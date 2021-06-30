# Add Kubernetes applications automatically

Once a MicroK8s cluster is set up on Nimbus, common Bioinformatics applications can be made to deploy automatically using Ansible.

First ensure that Ansible is installed on your instance. The following one-line command will run the MicroK8s commands for deploying each application, and you should get some instructions on how to run the application in the final "task" of the Ansible Playbook command.

Run the command below for each application, ensuring to follow the prompts that come.

*Note: If this is not the first deployment, and there is already a MicroK8s service exposed with the same name (e.g. conda-jupyternotebook), you will need rename the service for this deployment in the relevant deployment yaml manifest.*

## Conda Jupyter Notebook

    ansible-playbook ansible_scripts/ansible-miniconda3.yaml -i ansible_scripts/variables

## RStudio Server

    ansible-playbook ansible_scripts/ansible-rstudio.yaml -i ansible_scripts/variables