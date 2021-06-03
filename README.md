# MicroK8s Cluster on Nimbus

"MicroK8s is the smallest, fastest, fully-conformant Kubernetes that tracks upstream releases and makes clustering trivial." - [MicroK8s Canonical](https://microk8s.io/docs). If you have a number of Nimbus instances and would like to make use of them as multiple nodes for the one machine for your project's compute requirements, then MicroK8s is the simplest way to do that.
Before starting, you will need to have:
- An instance for the master node
- 1 or more instances as additional nodes

## Install MicroK8s on Nimbus (Linux)

The following instructions are for installation on Linux. For other operating systems, see the MicoK8s [documentation](https://microk8s.io/docs/install-alternatives).

On your instance, install MicroK8s. We will refer to this instance as your master node:

    sudo snap install microk8s --classic --channel=1.19

Check the status of your MicroK8s node:

    sudo microk8s status --wait-ready

Enable services (such as dashboard, dns, registry, istio, and storage) to perform fundamental tasks for the node:

    sudo microk8s enable dashboard dns registry istio storage

You can also enable other services if you know what you need by checking the list [here](https://microk8s.io/docs/addons#heading--list) or running the following command: 

    sudo microk8s status
    
## Access Kubernetes

Once MicroK8s is running, you can access Kubernetes using the 'kubectl' command line tool. Make sure to always prepend with 'microk8s' (i.e. 'microk8s kubectl') to avoid any conflicts with existing or future installs of kubectl.

To view your master node (current instance):

    sudo microk8s kubectl get nodes

## Adding storage

A StorageClass object is a set of rules created for accessing storage from the host machine to the cluster. In order to access storage to the cluster, a storage request called a Persistent Volume Claim (PVC) has to be created to prompt the cluster to provision storage requirements under the StorageClass object's set of rules.

### Default storage

The storage service that we have previously enabled is MicroK8s' default StorageClass object.  

**NOTE: This method of adding storage will use up the volume allocation of the machine's root disk, rather than any additional data volume disks. It is recommended that this method be used only for holding small amounts of data that are easily replaceable, such as metadata downloaded from a repository.**

To create a storage request using the default method, save the following contents in a file and name it pvc-default.yaml:

    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
        name: storage1
        spec:
        accessModes:
            - ReadWriteOnce
        resources:
            requests:
            storage: 1Gi
        storageClassName: microk8s-hostpath

Then create the request:

    sudo microk8s kubectl create -f pvc-default.yaml

You will find that a new 1GB storage has now been created as a persistent volume claim, which can now be assigned to a pod or application.

### Data storage

MicroK8s can work with the external Openstack cloud provider to dynamically provision and create data volumes (called cinder volumes) on your Nimbus project. You will still create a storage request via a PVC, but under a different StorageClass.

First, the Openstack cloud provider needs to be set up with Kubernetes.

Git clone the Openstack cloud provider repository which contains some manifest files that we will use:

    git clone https://github.com/kubernetes/cloud-provider-openstack.git

On your Nimbus dashboard, create an application credential, which will give you an ID and a secret:

    Identity > Application Credentials > Create Application Credential

On your instance, make the following directory and change your directory to it:

    sudo mkdir ~/.kube
    cd ~/.kube

Using the application credential ID and secret, save the following contents and name it `cloud.conf`:

    [Global]
    auth-url=https://nimbus.pawsey.org.au:5000/v3
    application-credential-id=REPLACE-WITH-YOUR-APPLICATION-CREDENTIAL-ID
    application-credential-secret=REPLACE-WITH-YOUR-APPLICATION-CREDENTIAL-SECRET

As the above cloud configuration file is passed via Kubernetes secrets, the cloud.conf contents need to be encoded with base64:

    base64 -w 0 ~/.kube/cloud.conf

Save the above secret to the manifest `csi-secret-cinderplugin.yaml`:

        cd ~/cloud-provider-openstack
        
        sed -i 's/cloud.conf: .*/cloud.conf: REPLACE-WITH-YOUR-SECRET/g' manifests/cinder-csi-plugin/csi-secret-cinderplugin.yaml

Create Kubernetes secret on MicroK8s:

    sudo microk8s kubectl create -f manifests/cinder-csi-plugin/csi-secret-cinderplugin.yaml

Edit the paths for Microk8s on the following manifests:

    sed -i 's+/var/lib+/var/snap/microk8s/common/var/lib+g' manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml

    sed -i 's+/etc/config/+~/.kube+g' manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml

    sed -i 's+/var/lib+/var/snap/microk8s/common/var/lib+g' manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml

    sed -i 's+/etc/config/+~/.kube+g' manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml

Finally, deploy the Openstack cloud provider:

    sudo microk8s kubectl apply -f manifests/cinder-csi-plugin/

Check that they are running:

    sudo microk8s kubectl get pods -n kube-system

Now that the Openstack provider has been set up with Kubernetes, the next step is to write a StorageClass object manifest. Name it `data-vol-sc.yaml` or a name that helps you identify it as the StorageClass object for data volumes:

    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
        name: data-vol-sc
    provisioner: cinder.csi.openstack.org

Then create it:

    sudo microk8s kubectl create -f data-vol-sc.yaml

Check that it has been created successfully:

    sudo microk8s kubectl get sc data-vol-sc

Then write a PVC manifest `data-pvc.yaml' for the amount of storage you would like for your application, noting that you can use the same PVC for as many applications as you need, much the same way you would use any storage volume:

    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
    name: data-pvc
    spec:
    accessModes:
    - ReadWriteOnce
    resources:
        requests:
        storage: 1Gi
    storageClassName: data-vol-sc 

Create the request as such:

    sudo microk8s kubectl create -f data-pvc.yaml

Check that it has been created successfully:

    sudo microk8s kubectl get pvc data-pvc

On your Nimbus dashboard, you should now see a new volume that has the description "Created by OpenStack Cinder CSI driver" and a file system that it has been attached to, usually `/dev/vdc`. Make sure to mount `/dev/vdc` to a `/data` folder on your instance so that you can read and write all your data on there with the applications that you will be using.

    sudo mkdir /data
    sudo chown ubuntu /data
    sudo mount /dev/vdc /data

## Adding an application

Applications can be added as a single application pod, or a collection of applications in one pod. You can assign specific resources to the pod, or use the default settings. 

**For automatic deployment of the below applications, see [here](README-ansible.md).**

If you have an existing container on your instance, Kubernetes will look for it first before looking up on public registries. Ensure that you indicate the repository, name and tag of the image in the image field under containers.

### RStudio application

In the application manifest for an RStudio deployment, we will use the rocker/tidyverse:4.0.3 image. You will also mount the storage volume you created above to the /home/rstudio path in order to have all your output data saved to the instance.

Save the following contents in a file and name it rstudio-deployment.yaml:

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: rstudio-deployment
    labels:
        app: rstudio
    spec:
    selector:
        matchLabels:
        app: rstudio
    template:
        metadata:
        labels:
            app: rstudio
        spec:
        containers:
        - name: rstudio
            image: rocker/tidyverse:4.0.3
            ports:
            - containerPort: 8787
            volumeMounts:
            - mountPath: '/home/rstudio/'
            name: rstudio-data
        volumes:
        - name: rstudio-data
            persistentVolumeClaim:
            claimName: storage1        

Deploy this pod on microK8s:

    sudo microk8s kubectl apply -f rstudio-deployment.yaml --env="PASSWORD=replace-with-your-own-password"

Verify the deployment and check that the assigned pod is running:

    sudo microk8s kubectl get deployment
    sudo microk8s kubectl get pods

Then expose the deployment as a service:

    sudo microk8s kubectl expose deployment rstudio-deployment --target-port=8787 --name=rstudio-server --type=NodePort

Now you will be able to access RStudio via its assigned port. The assigned port number can be found under 'PORT(S):

    sudo microk8s kubectl get svc

On your local computer, enable port forwarding to access RStudio via a web browser:

    ssh -i ~/.ssh/YOUR_NIMBUS_KEYPAIR_FILE -N -f -L PORT_NUMBER:localhost:PORT_NUMBER ubuntu@YOUR MICROK8S_INSTANCE_IP_ADDRESS

Finally, go to a web browser and enter the following URL to run RStudio:

    http://localhost:PORT_NUMBER

### Conda Jupyter notebook application

The same can be done for a Conda application. The image we are using here is continuumio/miniconda3:4.9.2. In order to run Conda in a Jupyter notebook, we will have the container initiate a bash command for Conda to install Jupyter and create a notebook directory. 

Save the following contents in a file and name it miniconda3-deployment.yaml:

    apiVersion: v1
    kind: Pod
    metadata:
    name: miniconda3-pod
    labels:
        app: miniconda3
    spec:
    containers:
    - name: miniconda3
        image: continuumio/miniconda3:4.9.2
        env:
        - name: JUPYTERCMD
        value: "conda install jupyter -y --quiet && /opt/conda/bin/jupyter notebook --notebook-dir=/opt/notebooks --ip='0.0.0.0' --port=8888 --no-browser --allow-root"
        command: ["bash"]
        args: ["-c", "$(JUPYTERCMD)"]
        ports:
        - containerPort: 8888       
        volumeMounts:
        - mountPath: '/opt/notebooks/'
        name: miniconda3-data
    volumes:
    - name: miniconda3-data
        persistentVolumeClaim:
        claimName: storage1

Deploy this pod on microK8s:
    
    sudo microk8s kubectl apply -f miniconda3-deployment.yaml

Verify the deployment and check that the assigned pod is running:

    sudo microk8s kubectl get pods

Then expose the deployment as a service:
    
    sudo microk8s kubectl expose pod miniconda3-pod --target-port=8888 --name=conda-jupyternotebook --type=NodePort

Now you will be able to access the Jupyter notebook via its assigned port. The assigned port number can be found under 'PORT(S):
    
    sudo microk8s kubectl get svc

On your local computer, enable port forwarding to access the notebook via a web browser:

    ssh -i ~/.ssh/YOUR_NIMBUS_KEYPAIR_FILE -N -f -L PORT_NUMBER:localhost:PORT_NUMBER ubuntu@YOUR MICROK8S_INSTANCE_IP_ADDRESS

Finally, go to a web browser and enter the following URL to run your Jupyter Notebook:

    http://localhost:PORT_NUMBER
 
 You will require a token that was generated by Conda. Run the command below to retrieve this token, then copy the token and enter it on the web browser when prompted:

    sudo microk8s kubectl logs miniconda3-pod

## Forming a cluster

Next, you can form a cluster by adding other instances (as nodes) to the master node. To add more nodes:

    sudo microk8s add-node

You should see some instructions for joining another instance as a node to the master node. Copy the command that looks like 'microk8s join <master>:<port>/<token>' and run it on the other instance you would like to join as an additional node.

*Note that before doing so, you need to install MicroK8s on the other instance(s) as well.*

Once the node is successfully added, you will see its status change from NotReady to Ready:

    sudo microk8s kubectl get no

At any time, you may also remove a node from a cluster. On the node you want to remove, run:

    sudo microk8s leave

Then go to all of the remaining nodes (including the master node) and remove permanently:

    sudo microk8s remove-node <name of node>

## Start or stop MicroK8s

To stop or start your MicroK8s cluster, you can use the following commands, respectively:

    sudo microk8s stop
    sudo microk8s start