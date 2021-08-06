# MicroK8s Cluster on Nimbus
This doumentation is for using Kubernetes on your Nimbus instance(s). The steps will enable you to run your own Kubernetes cluster and automatically deploy applications such as RStudio and JupyterHub.

If you have a number of Nimbus instances and would like to make use of them as a cluster for your project's compute requirements, then MicroK8s is the simplest way to do that.

Before starting, you will need to have:
- An instance for the master node
- 1 or more instances as additional nodes (as required)

## Requirements

First ensure that Ansible is installed on your instance. To install Ansible, run the following:

    sudo apt install --yes software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install --yes ansible

## Install MicroK8s on Nimbus (Linux)

Installing MicroK8s on Nimbus is simple, and you can choose to have it done automatically (recommended) OR [step-by-step (for eperienced Linux users only)](README-steps.md).

### Install automatically (recommmended)

To assist with an easy installation process, you can run our automated cluster deployment with storage volume added by following these instructions:

1)  Go to your Nimbus dashboard and save your application credentials using the left-hand navigation bar as follows:

    Identity > Application Credentials
    
    Click on **+Create Application Credential** and give it a name. You don't have to fill out the rest of the form. Make sure to have this file handy as you will be prompted to enter the ID and secret that is in the file.

2) Know the data volume storage you would like to create, in gigabytes, e.g. 100

3) Once you have the above two, run the following on a terminal for your Nimbus instance. Note that installation will take at least 15 minutes. Keep the terminal open and active during this time.

        git clone https://github.com/audreystott/microk8s-on-nimbus.git
        cd microk8s-on-nimbus
        ansible-playbook /ansible_install_MicroK8s_with_volume.yaml -i variables


## Add an application

Applications can be added as a single application pod, or a collection of applications in one pod. You can assign specific resources to the pod, or use the default settings. 

### Add an application automatically (recommended)

The following one-line command will run the MicroK8s commands for deploying each application, and you should get some instructions on how to run the application in the final "task" of the Ansible Playbook command.

Run the command below for each application, ensuring to follow the prompts that come.

*Note: If this is not the first deployment, and there is already a MicroK8s service exposed with the same name (e.g. conda-jupyternotebook), you will need rename the service for this deployment in the relevant deployment yaml manifest.*

#### Conda Jupyter Notebook

    ansible-playbook ansible_scripts/ansible-miniconda3.yaml -i ansible_scripts/variables

#### RStudio Server

    ansible-playbook ansible_scripts/ansible-rstudio.yaml -i ansible_scripts/variables


To add an application step-by-step (for experienced Linux users), see [here](README-app-steps.md).


## Form a cluster (as required)

Next, you can form a cluster by adding other instances (as nodes) to the master node. To add more nodes:

    sudo microk8s add-node

You should see some instructions for joining another instance as a node to the master node. Copy the command that looks like 'microk8s join <master>:<port>/<token>' and run it on the other instance you would like to join as an additional node.

*Note that before doing so, you need to install MicroK8s on the other instance(s) as well.*

Once the node is successfully added, you will see its status change from NotReady to Ready:

    sudo microk8s kubectl get no

At any time, you may also remove a node from a cluster. On the node you want to remove, run:

    sudo microk8s leave

Then go to all of the remaining nodes (including the master node) and remove permanently:

    sudo microk8s remove-node <name of node>

## Start or stop MicroK8s (as required)

To stop or start your MicroK8s cluster, you can use the following commands, respectively:

    sudo microk8s stop
    sudo microk8s start