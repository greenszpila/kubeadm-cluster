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
* terraform init

### Deploy one master and two worker nodes kubeadm 1.19 cluster

By default the resources are being deployed to the `us-east-2` region.
To deploy cluster to the eu-west region:

`terraform apply -var-file eu-west.tfvars` 

You could create your own variable file or edit the `eu-west.tfvars` with the following details which are self explanatory:

```
ec2_instance_type = "t2.large"
ami_key_pair_name = "my_key"
private_key_location = "~/location/my_key.pem"
ec2_instance_region = "ap-east-1"
```

then run the `terraform apply -var-file yourVarFile.tfvars` 

## SSH to the Master node

Copy and paste the auto-generated command to connect to the master node: 

`ssh_to_master = "ssh -i ~/coding/key_name.pem ubuntu@18.191.25.152"` 

# Verify the worker nodes have joined the cluster successfully:

`kubectl get nodes`

# Verify the cluster

Create a deployment named nginx:

`kubectl create deployment nginx --image=nginx` 
`kubectl expose deploy nginx --port 80 --target-port 80 --type NodePort` 
`kubectl get services` 

To test that everything is working, visit

- http://worker_1_ip:nginx_port or, 
- http://worker_2_ip:nginx_port 

through a browser or `curl` on your local machine. You will see Nginx’s familiar welcome page.

Install New Relic Kubernetes integration with Pixie by following the below guide:

- https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/installation/kubernetes-integration-install-configure/

Verify if all pods are in running state with:

`kubectl get pods -n newrelic` 

## Clean up

`terraform destroy` or 
`terraform destroy -var-file eu-west.tfvars` if the var file was used.

Delete the hosts file if you are planning to use the same directory for the future tf deployments. 

`rm -rf hosts` 


