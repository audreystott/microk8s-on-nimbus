#!/bin/bash

pubkey_path="$1"
rstudio_password="$2"
rstudio_port_number=$(sudo microk8s kubectl get svc | grep -oP '8787:.{0,5}' | sed 's/^.*://')
public_ip_address=$(curl ifconfig.me)

echo "-----------------------------------------------------------------------------------------------------------------------------------


        Run the following command on your local computer to enable port forwarding from this instance to your local computer:       
                ssh -i $pubkey_path -N -f -L $rstudio_port_number:localhost:$rstudio_port_number ubuntu@$public_ip_address                                         

        Then go to a web browser and enter the following URL to run RStudio:                                                        
                http://localhost:$rstudio_port_number                                                                                              
                username = rstudio                                                                                                   
                password = what your entered when prompted at the start                                                             

        All RStudio sessions and associated data will be saved under /data/rstudio.                                                                    

        IMPORTANT: After exiting RStudio, close the 8787 port on your local computer:                                               
                   lsof -ti:8787 | xargs kill -9                                                                                    


-----------------------------------------------------------------------------------------------------------------------------------"