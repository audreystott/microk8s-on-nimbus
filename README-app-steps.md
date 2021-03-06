# Add an application on Kubernetes step-by-step (for experienced Linux users)

If you have an existing container on your instance, Kubernetes will look for it first before looking up on public registries. Ensure that you indicate the repository, name and tag of the image in the image field under containers.

1. RStudio application

    In the application manifest for an RStudio deployment, we will use the rocker/tidyverse:4.0.3 image. You will also mount the storage volume you created above to the /home/rstudio path in order to have all your output data saved to the instance.

    Save the following contents in a file and name it rstudio-deployment.yaml:

        apiVersion: apps/v1
        kind: Deployment
        metadata:
        name: rstudio-deployment
        labels:
            app: rstudio
        spec:
        selector:
            matchLabels:
            app: rstudio
        template:
            metadata:
            labels:
                app: rstudio
            spec:
            containers:
            - name: rstudio
                image: rocker/tidyverse:4.0.3
                ports:
                - containerPort: 8787
                volumeMounts:
                - mountPath: '/home/rstudio/'
                name: rstudio-data
            volumes:
            - name: rstudio-data
                persistentVolumeClaim:
                claimName: data-pvc        

    Deploy this pod on microK8s:

        sudo microk8s kubectl apply -f rstudio-deployment.yaml --env="PASSWORD=replace-with-your-own-password"

    Verify the deployment and check that the assigned pod is running:

        sudo microk8s kubectl get deployment
        sudo microk8s kubectl get pods

    Then expose the deployment as a service:

        sudo microk8s kubectl expose deployment rstudio-deployment --target-port=8787 --name=rstudio-server --type=NodePort

    Now you will be able to access RStudio via its assigned port. The assigned port number can be found under 'PORT(S):

        sudo microk8s kubectl get svc

    On your local computer, enable port forwarding to access RStudio via a web browser:

        ssh -i ~/.ssh/YOUR_NIMBUS_KEYPAIR_FILE -N -f -L PORT_NUMBER:localhost:PORT_NUMBER ubuntu@YOUR MICROK8S_INSTANCE_IP_ADDRESS

    Finally, go to a web browser and enter the following URL to run RStudio:

        http://localhost:PORT_NUMBER

    The username is rstudio, and the password is what you entered at runtime.

2. Conda Jupyter notebook application

    The same can be done for a Conda application. The image we are using here is continuumio/miniconda3:4.9.2. In order to run Conda in a Jupyter notebook, we will have the container initiate a bash command for Conda to install Jupyter and create a notebook directory. 

    Save the following contents in a file and name it miniconda3-deployment.yaml:

        apiVersion: v1
        kind: Pod
        metadata:
        name: miniconda3-pod
        labels:
            app: miniconda3
        spec:
        containers:
        - name: miniconda3
            image: continuumio/miniconda3:4.9.2
            env:
            - name: JUPYTERCMD
            value: "conda install jupyter -y --quiet && /opt/conda/bin/jupyter notebook --notebook-dir=/opt/notebooks --ip='0.0.0.0' --port=8888 --no-browser --allow-root"
            command: ["bash"]
            args: ["-c", "$(JUPYTERCMD)"]
            ports:
            - containerPort: 8888       
            volumeMounts:
            - mountPath: '/opt/notebooks/'
            name: miniconda3-data
        volumes:
        - name: miniconda3-data
            persistentVolumeClaim:
            claimName: data-pvc

    Deploy this pod on microK8s:
        
        sudo microk8s kubectl apply -f miniconda3-deployment.yaml

    Verify the deployment and check that the assigned pod is running:

        sudo microk8s kubectl get pods

    Then expose the deployment as a service:
        
        sudo microk8s kubectl expose pod miniconda3-pod --target-port=8888 --name=conda-jupyternotebook --type=NodePort

    Now you will be able to access the Jupyter notebook via its assigned port. The assigned port number can be found under 'PORT(S):
        
        sudo microk8s kubectl get svc

    On your local computer, enable port forwarding to access the notebook via a web browser:

        ssh -i ~/.ssh/YOUR_NIMBUS_KEYPAIR_FILE -N -f -L PORT_NUMBER:localhost:PORT_NUMBER ubuntu@YOUR MICROK8S_INSTANCE_IP_ADDRESS

    Finally, go to a web browser and enter the following URL to run your Jupyter Notebook:

        http://localhost:PORT_NUMBER

    You will require a token that was generated by Conda. Run the command below to retrieve this token, then copy the token and enter it on the web browser when prompted:

        sudo microk8s kubectl logs miniconda3-pod