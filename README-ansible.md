# Deploying Kubernetes applications automatically

Once a MicroK8s cluster is set up on Nimbus, common Bioinformatics applications can be made to deploy automatically using Ansible.

First ensure that Ansible is installed on your instance. 

Then run the command below, ensuring to follow the prompts that come:

    ansible-playbook ansible_scripts/ansible-miniconda3.yaml -i ansible_scripts/variables

*Note: If there is already a MicroK8s service exposed with the same name (conda-jupyternotebook), you will need to delete that service or rename the service for this deployment to another name in the miniconda3-deployment.yaml manifest.*

You should get some instructions on how to use the application in the final "task" of the Ansible Playbook command.