# MicroK8s Cluster on Nimbus

This documentation is for using Kubernetes on your Nimbus instance(s). The steps will enable you to run your own Kubernetes cluster and automatically deploy applications such as RStudio and JupyterHub.

If you have a number of Nimbus instances and would like to make use of them as a cluster for your project's compute requirements, then MicroK8s is the simplest way to do that.

## Before you begin

Before starting, you will need to have:
- An instance for the master node
- 1 or more instances as additional nodes (as required)

## Install MicroK8s on Nimbus

On all instances for the cluster, install MicroK8s:

	sudo snap install microk8s --classic --channel=1.19/stable

Turn on the following services for each of the instance:

	sudo microk8s enable dashboard dns registry ha-cluster

You can also enable other services if you know what you need by checking the list [here](https://microk8s.io/docs/addons#heading--list) or running the following command: 

	sudo microk8s status	

## Access Kubernetes

Once MicroK8s is running, you can access Kubernetes using the 'kubectl' command line tool. Make sure to always prepend with 'microk8s' (i.e. 'microk8s kubectl') to avoid any conflicts with existing or future installs of kubectl.
To view your master node (current instance):

	sudo microk8s kubectl get nodes

## Add storage

MicroK8s can work with the external Openstack cloud provider to dynamically provision and create data volumes (called cinder volumes) on your Nimbus project. You will still create a storage request via a PVC, under a StorageClass.

First, the Openstack cloud provider needs to be set up with Kubernetes. Git clone the following repository, which contains some manifest files that we will use:

	git clone https://github.com/audreystott/microk8s-on-nimbus

On your Nimbus dashboard, create an application credential, which will give you an ID and a secret:
Identity > Application Credentials > Create Application Credential

On your instance, make the following directory and change your directory to it:

	sudo mkdir ~/.kube
	cd ~/.kube

Using the application credential ID and secret, save the following contents, **(making sure to add in your application credential id and secret)**, then  name it `cloud.conf`:

	[Global]
	auth-url=https://nimbus.pawsey.org.au:5000
	application-credential-id=
	application-credential-secret=
	identity-api-version=3
	auth-type=v3applicationcredential

Encode the `cloud.conf` file with base64 (required for passing as a Kubernetes secret in the next step):

	base64 -w 0 ~/.kube/cloud.conf

Save the secret to the manifest `csi-secret-cinderplugin.yaml`, by running the below commands (taking note to replace the phrase `REPLACE-WITH-YOUR-SECRET` with the base64 secret from the previous step):

	cd ~/cloud-provider-openstack
	sed -i 's/cloud.conf: .*/cloud.conf: REPLACE-WITH-YOUR-SECRET/g' manifests/cinder-csi-plugin/csi-secret-cinderplugin.yaml

Create the Kubernetes secret on MicroK8s:

	sudo microk8s kubectl create -f manifests/cinder-csi-plugin/csi-secret-cinderplugin.yaml

Run the following commands to edit the paths to the Kubernetes libraries on the following manifests:

	sed -i 's+/var/lib+/var/snap/microk8s/common/var/lib+g' manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml
 
	sed -i 's+/etc/config+~/.kube+g' manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml
 
	sed -i 's+/var/lib+/var/snap/microk8s/common/var/lib+g' manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml
 
	sed -i 's+/etc/config+~/.kube+g' manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml

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

Then copy and paste the following contents and name it `data-pvc.yaml` for the amount of storage you would like for your application (change the number accordingly), noting that you can use the same PVC for as many applications as you need, much the same way you would use any storage volume:

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

On your Nimbus dashboard, you should now see a new volume that has the description "Created by OpenStack Cinder CSI driver" and a file system that it has been attached to, usually `/dev/sdc` (`/dev/vdc` if it is an older Nimbus instance). 

*If it isn't attached, manually attach the volume to the instance on your Nimbus dashboard, and format the volume:*

	sudo mkfs.ext4 /dev/sdc

Then, make sure to mount `/dev/sdc` to a `/data` folder on your instance so that you can read and write all your data on there with the applications that you will be using.

	sudo mkdir /data
 
	sudo chown ubuntu /data
 
	sudo mount /dev/sdc /data

## Form a cluster

**Note that before doing so, you need to install MicroK8s on the other instance(s) as above.**

Now you can form a cluster by adding other instances (as nodes) to the master node. This step is optional. To add more nodes:

    sudo microk8s add-node

You should see some instructions for joining another instance as a node to the master node. Copy the command that looks like 'microk8s join <master>:<port>/<token>' and run it on the other instance you would like to join as an additional node.

Once the node is successfully added, you will see its status change from NotReady to Ready:

    sudo microk8s kubectl get no

**To add a third node, run the `add-node` command from the node you just added.**

At any time, you may also remove a node from a cluster. On the node you want to remove, run:

    sudo microk8s leave

Then go to all of the remaining nodes (including the master node) and remove permanently:

    sudo microk8s remove-node <name of node>

## Start or stop MicroK8s (as required)

To stop or start your MicroK8s cluster, you can use the following commands, respectively:

    sudo microk8s stop
    sudo microk8s start
