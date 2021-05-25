#!/bin/bash

sudo snap install microk8s --classic --channel=1.19
sudo microk8s enable dashboard dns registry istio storage

