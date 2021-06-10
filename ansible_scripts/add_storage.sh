#!/bin/bash

echo "apiVersion: v1
kind: PersistentVolumeClaim
metadata:
name: data-pvc
spec:
accessModes:
- ReadWriteOnce
resources:
    requests:
    storage: $1Gi
storageClassName: data-vol-sc " > data-pvc.yaml

sudo microk8s kubectl create -f data-pvc.yaml