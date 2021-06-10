#!/bin/bash

echo "apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
    name: data-vol-sc
provisioner: cinder.csi.openstack.org" > data-vol-sc.yaml

sudo microk8s kubectl create -f data-vol-sc.yaml