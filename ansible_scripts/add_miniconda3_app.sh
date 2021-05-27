#!/bin/bash

pubkey_path="$1"
miniconda3_port_number=$(sudo microk8s kubectl get svc | grep -oP '8888:.{0,5}' | sed 's/^.*://')
public_ip_address=$(curl ifconfig.me)
jupyternotebook_token=$(sudo microk8s kubectl logs deployment.apps/miniconda3-deployment | grep -oP -m 1 'token=.{0,}' | sed 's/^.*=//')

echo 'Run the following command on your local computer to enable port forwarding from this instance to your local computer:
ssh -i '$pubkey_path' -N -f -L '$miniconda3_port_number':localhost:'$miniconda3_port_number' ubuntu@'$public_ip_address'

Then go to a web browser and enter the following URL to run your conda Jupyter notebook: http://localhost:'$miniconda3_port_number'

The token to your Jupyter notebook is: '$jupyternotebook_token'

****After exiting the Jupyter Notebook, close the '$miniconda3_port_number' port on your local computer****: lsof -ti:'$miniconda3_port_number' | xargs kill -9'
