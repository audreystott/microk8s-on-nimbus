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

Turn on the following services for the node:

    sudo microk8s enable dashboard dns registry istio storage

You can also enable other services if you know what you need by checking the list [here](https://microk8s.io/docs/addons#heading--list) or running the following command: 

    sudo microk8s status
    
## Access Kubernetes

Once MicroK8s is running, you can access Kubernetes using the 'kubectl' command line tool. Make sure to always prepend with 'microk8s' (i.e. 'microk8s kubectl') to avoid any conflicts with existing or future installs of kubectl.

To view your master node (current instance):

    sudo microk8s kubectl get nodes

## Adding storage

MicroK8s comes with a default StorageClass object add-on that we have previously enabled. In order to add storage to the cluster, a storage request is created to prompt the cluster to provision storage requirements from the host instance.

To create a storage request, save the following contents in a file and name it pvc.yaml:

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

    sudo microk8s kubectl create -f pvc.yaml

You will find that a new 1GB storage has now been created as a persistent volume claim, which can now be assigned to a pod or application.

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