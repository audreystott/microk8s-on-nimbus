#!/bin/bash

sudo microk8s kubectl apply -f rstudio-deployment.yaml --env="PASSWORD={{ rstudio_password }}"
sudo microk8s kubectl expose deployment rstudio-deployment --target-port=8787 --name=rstudio-server --type=NodePort


echo '------------------------------------------------------------------------------------------- 


Run the following command on your local computer to enable port forwarding from this instance to your local computer:
ssh -i {{ pubkey_path }} -N -f -L {{ rstudio_port_number }}:localhost:{{ rstudio_port_number }} ubuntu@{{ public_ip_address }}

Then go to a web browser and enter the following URL to run RStudio:
http://localhost:{{ rstudio_port_number }}

****After exiting RStudio, close the 8787 port on your local computer****:
lsof -ti:8787 | xargs kill -9

-------------------------------------------------------------------------------------------'