# Install MicroK8s on Nimbus step-by-step (for experienced Linux users)

1) Install

    The following instructions are for installation on Linux. For other operating systems, see the MicoK8s [documentation](https://microk8s.io/docs/install-alternatives).

    On your instance, install MicroK8s. We will refer to this instance as your master node:

        sudo snap install microk8s --classic --channel=1.19

    Check the status of your MicroK8s node:

        sudo microk8s status --wait-ready

    Enable services (such as dashboard, dns, registry, istio, and storage) to perform fundamental tasks for the node:

        sudo microk8s enable dashboard dns registry istio storage

    You can also enable other services if you know what you need by checking the list [here](https://microk8s.io/docs/addons#heading--list) or running the following command: 

        sudo microk8s status
    
2) Access Kubernetes

    Once MicroK8s is running, you can access Kubernetes using the 'kubectl' command line tool. Make sure to always prepend with 'microk8s' (i.e. 'microk8s kubectl') to avoid any conflicts with existing or future installs of kubectl.

    To view your master node (current instance):

        sudo microk8s kubectl get nodes

3) Add storage

    A StorageClass object is a set of rules created for accessing storage from the host machine to the cluster. In order to access storage to the cluster, a storage request called a Persistent Volume Claim (PVC) has to be created to prompt the cluster to provision storage requirements under the StorageClass object's set of rules.

    *  Default storage

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

    *   Data storage (recommended)

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
                storage: $1Gi
            storageClassName: data-vol-sc 

        Create the request as such:

            sudo microk8s kubectl create -f data-pvc.yaml

        Check that it has been created successfully:

            sudo microk8s kubectl get pvc data-pvc

        On your Nimbus dashboard, you should now see a new volume that has the description "Created by OpenStack Cinder CSI driver" and a file system that it has been attached to, usually `/dev/vdc`. Make sure to mount `/dev/vdc` to a `/data` folder on your instance so that you can read and write all your data on there with the applications that you will be using.

            sudo mkdir /data
            sudo chown ubuntu /data
            sudo mount /dev/vdc /data