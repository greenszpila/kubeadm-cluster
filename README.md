# terraform-kubeadm-3node-cluster 

Bootstraping kubeadm kubernetes cluster using terraform and ansible. 
I am using remote-exec and local-exec to demonstrate two different ways of configuring hosts. 

### Dependencies

* terraform
* ansible
* git
* aws account and aws cli installed 

### Installing

* git pull repository:  `https://github.com/greenszpila/kubeadm-cluster.git`

### Executing program

### To spin up simple EC2 Ubuntu 18.04 
By default the resources are being deployed to the `us-east-2` region.
To deploy cluster to the eu-west region:

`terraform apply -var-file eu-west.tfvars` 

You could create your own variable file or edit the above with the following details which are self explanatory:

```
ec2_instance_type = "t2.medium"
ami_key_pair_name = "aws-keypair-name"
private_key_location = "~/location/key.pem"
ec2_instance_region = "aws-region"
```

then run the `terraform apply -var-file yourVarFile.tfvars` 

## After the nodes have been successfully deployed follow the cluster initialization steps:

Choose one of the nodes to become a Master. SSH to it with your aws ssh key. 

`ssh -i kriss-eu.pem ubuntu@54.154.101.211`

# Initialize the cluster (run only on the master):

`sudo kubeadm init --pod-network-cidr=10.244.0.0/16`


# Set up local kubeconfig (run only on the master):

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```


# Apply Flannel CNI network overlay:(run only on the master):
`kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`

# Join the worker nodes to the cluster, run only on the worker nodes.

`sudo kubeadm join [OUTPUT_FROM_KUBEADM_INIT_COMMAND]`

example command:

```
sudo kubeadm join 172.31.29.245:6443 --token wnjogj.jb4e21hky52pbl1q \
    --discovery-token-ca-cert-hash  sha256:ca7f2267d03b137cfcf6975bcdd2ccab4e4e0411f82c70510c55a543a37b27e1    
```

# Verify the worker nodes have joined the cluster successfully:

`kubectl get nodes`

# Install Helm on the Master

Install Helm 3
Carry out following steps on the master node.

Install Helm:
`curl -L https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash`

 
Validate Helm has been installed successfully:
`helm version`


Add the stable Helm charts:
`helm repo add stable https://charts.helm.sh/stable`

