#!/bin/bash

echo "kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: $1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: $2Gi
  storageClassName: microk8s-hostpath" > pvc-test.yaml

sudo microk8s kubectl create -f pvc-test.yaml