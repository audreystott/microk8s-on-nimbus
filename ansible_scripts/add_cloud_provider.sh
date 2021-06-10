#!/bin/bash

#Git clone the Openstack cloud provider repository which contains some manifest files that we will use
git clone https://github.com/kubernetes/cloud-provider-openstack.git

#On your instance, make the following directory and change your directory to it
sudo mkdir ~/.kube
cd ~/.kube

#Using the application credential ID and secret, save the following contents and name it cloud.conf
echo "[Global]
auth-url=https://nimbus.pawsey.org.au:5000/v3
application-credential-id=$1
application-credential-secret=$2" > cloud.conf

#As the above cloud configuration file is passed via Kubernetes secrets, the cloud.conf contents need to be encoded with base64
cloud_conf_secret=$(base64 -w 0 ~/.kube/cloud.conf)

#Save the above secret to the manifest csi-secret-cinderplugin.yaml
cd ~/cloud-provider-openstack
sed -i 's/cloud.conf: .*/cloud.conf: $cloud_conf_secret/g' manifests/cinder-csi-plugin/csi-secret-cinderplugin.yaml

#Create Kubernetes secret on MicroK8s
sudo microk8s kubectl create -f manifests/cinder-csi-plugin/csi-secret-cinderplugin.yaml

#Edit the paths for Microk8s on the following manifests
sed -i 's+/var/lib+/var/snap/microk8s/common/var/lib+g' manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml
sed -i 's+/etc/config/+~/.kube+g' manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml
sed -i 's+/var/lib+/var/snap/microk8s/common/var/lib+g' manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml
sed -i 's+/etc/config/+~/.kube+g' manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml

#Finally, deploy the Openstack cloud provider
sudo microk8s kubectl apply -f manifests/cinder-csi-plugin/