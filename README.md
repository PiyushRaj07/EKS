# EKS
EKS rootkit

if you cretae cluster and want to access for the first time :


eksctl utils associate-iam-oidc-provider --region us-east-1  --cluster  my-custom-networking-cluster --approve


aws eks --region us-east-1 update-kubeconfig --name my-custom-networking-cluster



Step 1: get node 

piyush@piyush-MacBook-Pro ~ % kubectl get no  -o wide

output:
NAME                         STATUS   ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP      OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-1-243.ec2.internal   Ready    <none>   25m   v1.28.3-eks-e71965b   10.0.1.243    34.207.213.148   Amazon Linux 2   5.10.198-187.748.amzn2.x86_64   containerd://1.6.19
ip-10-0-2-145.ec2.internal   Ready    <none>   25m   v1.28.3-eks-e71965b   10.0.2.145    3.83.79.41       Amazon Linux 2   5.10.198-187.748.amzn2.x86_64   containerd://1.6.19


##cretae namespace:kubectl create namespace ns-1

create pod1:
piyush@piyush-MacBook-Pro ~ % cat pod-1.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pod-1
  namespace: ns-1
spec:
  containers:
  - name: nginx-container
    image: nginx:latest




##command to check ip address of pod individual:

ie 
piyush@piyush-MacBook-Pro ~ % kubectl get pod -o wide -n ns-1
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE                         NOMINATED NODE   READINESS GATES
pod-1   1/1     Running   0          15m   10.0.2.198   ip-10-0-2-112.ec2.internal   <none>           <none>
pod-3   1/1     Running   0          40m   10.0.1.42    ip-10-0-1-140.ec2.internal   <none>           <none>


----
kubectl get pod pod-1 -n ns-1 -o jsonpath='{.status.podIP}'

10.0.2.198%                      

kubectl get pods -n ns-1 -o wide





custom networking examples :

my-custom-networking-cluster


vpc : 192.168.0.0/24	

private: 	
subnet s:
192.168.0.64/27: my-eks-custom-networking-vpc-Private A

192.168.0.96/27: my-eks-custom-networking-vpc-Private B


adding additional subnet:

aws ec2 associate-vpc-cidr-block --vpc-id $vpc_id --cidr-block 192.168.1.0/24


check association:
aws ec2 describe-vpcs --vpc-ids $vpc_id --query 'Vpcs[*].CidrBlockAssociationSet[*].{CIDRBlock: CidrBlock, State: CidrBlockState.State}' --out table

}
piyush@piyush-MacBook-Pro ~ % aws ec2 describe-vpcs --vpc-ids $vpc_id --query 'Vpcs[*].CidrBlockAssociationSet[*].{CIDRBlock: CidrBlock, State: CidrBlockState.State}' --out table

----------------------------------
|          DescribeVpcs          |
+-----------------+--------------+
|    CIDRBlock    |    State     |
+-----------------+--------------+
|  192.168.0.0/24 |  associated  |  --- now this is coming form the vpc we created using cloudformation stack
|  192.168.1.0/24 |  associated  |  --- i just associated above.

+-----------------+--------------+

Create as many subnets as you want to use in each Availability Zone that your existing subnets are in. 
The subnets must be created in a different VPC CIDR block than your existing subnets are 

n this example, one subnet is created in the new CIDR block in each Availability Zone that the current private subnets exist in. The IDs of the subnets created are stored in variables for use in later steps. T



new_subnet_id_1=$(aws ec2 create-subnet --vpc-id $vpc_id --availability-zone $az_1 --cidr-block 192.168.1.0/27 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-eks-custom-networking-vpc-PrivateSubnet01},{Key=kubernetes.io/role/internal-elb,Value=1}]' \
    --query Subnet.SubnetId --output text)
new_subnet_id_2=$(aws ec2 create-subnet --vpc-id $vpc_id --availability-zone $az_2 --cidr-block 192.168.1.32/27 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-eks-custom-networking-vpc-PrivateSubnet02},{Key=kubernetes.io/role/internal-elb,Value=1}]' \
    --query Subnet.SubnetId --output text)




 View the current subnets in your VPC.


aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --output table
piyush@piyush-MacBook-Pro ~ % new_subnet_id_1=$(aws ec2 create-subnet --vpc-id $vpc_id --availability-zone $az_1 --cidr-block 192.168.1.0/27 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-eks-custom-networking-vpc-PrivateSubnet01},{Key=kubernetes.io/role/internal-elb,Value=1}]' \
    --query Subnet.SubnetId --output text)
new_subnet_id_2=$(aws ec2 create-subnet --vpc-id $vpc_id --availability-zone $az_2 --cidr-block 192.168.1.32/27 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-eks-custom-networking-vpc-PrivateSubnet02},{Key=kubernetes.io/role/internal-elb,Value=1}]' \
    --query Subnet.SubnetId --output text)
piyush@piyush-MacBook-Pro ~ % aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --output table

---------------------------------------------------------------------
|                          DescribeSubnets                          |
+------------------+-------------------+----------------------------+
| AvailabilityZone |     CidrBlock     |         SubnetId           |
+------------------+-------------------+----------------------------+
|  us-east-1b      |  192.168.1.32/27  |  subnet-0cecf080c123397d2  |
|  us-east-1a      |  192.168.0.64/27  |  subnet-03e4382a8bb339fb8  |
|  us-east-1b      |  192.168.0.32/27  |  subnet-039a24601cee02573  |
|  us-east-1a      |  192.168.0.0/27   |  subnet-0a27965a5e528b05c  |
|  us-east-1b      |  192.168.0.96/27  |  subnet-0812fe0464c63818f  |
|  us-east-1a      |  192.168.1.0/27   |  subnet-0dfafa39a5ea660bf  |


Step 3: Configure Kubernetes resources



Set the AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG environment variable to true in the aws-node DaemonSet.


kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true

Retrieve the ID of your cluster security group and store it in a variable for use in the next step. Amazon EKS automatically creates this security group when you create your cluster.

cluster_security_group_id=$(aws eks describe-cluster --name $cluster_name --query cluster.resourcesVpcConfig.clusterSecurityGroupId --output text)



aws ec2 describe-instances --filters Name=network-interface.private-dns-name,Values=ip-192-168-0-101.ec2.internal \
--query 'Reservations[].Instances[].{AvailabilityZone: Placement.AvailabilityZone, SubnetId: SubnetId}'



Annotate:

kubectl annotate node ip-192-168-0-101.ec2.internal k8s.amazonaws.com/eniConfig=EniConfigName1

kubectl annotate node ip-192-168-0-84.ec2.internal k8s.amazonaws.com/eniConfig=EniConfigName2



------------------------------------
Doubt:
where is this subnet coming form:

i mean we create vpc and witin that vpc subnet we create range but in this we are creating subnet diffrent than our vpc 
also check the range of vpc --> subnet  is diff question is  this subnet within 192.168.0.0/24.

ie : aws document:
The subnets must be created in a different VPC CIDR block than your existing subnets are in( but i did not created any vpc)

|  192.168.1.0/24 |  associated  |





Assignmen: 1
check connectivity:
# From pod-2 in namespace ns-2, try to connect to a service running in pod-1
kubectl exec -it pod-2 -n ns-2 -- nc -zv <pod-1-IP-address> 80


 java-app-deployment-58979bd987-h7q9

in case there is no ping utility and curl
kubectl exec -it pod-1 -n ns-1 -- apt-get update
kubectl exec -it pod-1 -n ns-1 -- apt-get install -y iputils-ping
kubectl exec -it pod-1 -n ns-1 apt install curl

how to block ns-1 traffice to ns-2

# launch sample app
kubectl run my-shell --rm -i --tty --image ubuntu -n backend  -- /bin/bash 



# install telnet 

apt install telnetd -y


## mysql login 
apt install mysql-server
mysql --version

## mysql 

mysql -u mysql -ppasswd1 -h 10.0.2.227 employeedb 


## mysql  login form other pod to check connection 
mysql -u root -ppasswd1 -h mysql.database employeedb

## 

kubectl run -it --rm --image=mysql:8.0 -n database --restart=Never mysql-client  -- mysql -h mysql  -ppasswd1



node-1 : ip-10-0-2-223.ec2.internal
node-2: ip-10-0-1-249.ec2.internal
piyush@piyush-MacBook-Pro EKS % kubectl get pods -A
NAMESPACE     NAME                      READY   STATUS    RESTARTS   AGE
kube-system   aws-node-bll69            2/2     Running   0          27m
kube-system   aws-node-pn9sg            2/2     Running   0          27m
kube-system   coredns-58488c5db-dhnjm   1/1     Running   0          31m
kube-system   coredns-58488c5db-vg88v   1/1     Running   0          31m
kube-system   kube-proxy-l6vcr          1/1     Running   0          27m
kube-system   kube-proxy-m4kf2          1/1     Running   0          27m
ns-1          pod-1                     1/1     Running   0          14m
ns-1          pod-3                     1/1     Running   0          3m11s
ns-2          pod-2                     1/1     Running   0          12m
piyush@piyush-MacBook-Pro EKS % kubectl get pods -n ns-2 
NAME    READY   STATUS    RESTARTS   AGE
pod-2   1/1     Running   0          12m
piyush@piyush-MacBook-Pro EKS % kubectl get pods -n ns-1  
NAME    READY   STATUS    RESTARTS   AGE
pod-1   1/1     Running   0          15m
pod-3   1/1     Running   0          3m53s
piyush@piyush-MacBook-Pro EKS % 


check connectivity between nodes:
run this on pod-1:
kubectl exec -it pod-1 -n ns-1 -- /bin/bash
root@pod-1:/# ping 10.0.1.249
run this on pod-2:

kubectl exec -it pod-2 -n ns-2 -- /bin/bash
root@pod-1:/# ping 10.0.2.223


expected output:

root@pod-2:/# ping 10.0.2.223
PING 10.0.2.223 (10.0.2.223) 56(84) bytes of data.
64 bytes from 10.0.2.223: icmp_seq=1 ttl=254 time=0.857 ms
64 bytes from 10.0.2.223: icmp_seq=2 ttl=254 time=0.859 ms

this proves connection-between node -1 and node-2 pods


now lets block the traffic using NetworkPolicy:


pod-1---> pod2
root@pod-1:/# traceroute  10.0.2.191 
traceroute to 10.0.2.191 (10.0.2.191), 30 hops max, 60 byte packets
 1  ip-10-0-1-249.ec2.internal (10.0.1.249)  0.205 ms  0.013 ms  0.005 ms
 2  ip-10-0-2-223.ec2.internal (10.0.2.223)  0.938 ms  0.814 ms  0.936 ms
 3  ip-10-0-2-191.ec2.internal (10.0.2.191)  0.917 ms  0.900 ms  0.854 ms

inside same namespace: ns-1 to another pod in ns-1
root@pod-1:/# traceroute  10.0.1.17  
traceroute to 10.0.1.17 (10.0.1.17), 30 hops max, 60 byte packets
 1  ip-10-0-1-249.ec2.internal (10.0.1.249)  0.041 ms  0.007 ms  0.005 ms
 2  ip-10-0-1-17.ec2.internal (10.0.1.17)  0.040 ms  0.009 ms  0.008 ms


testing ns-2 to ns-1 :
 
 Command : curl -I 10.0.1.98:80 | head -1
 Result: ----------------------------------
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0   615    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK



Steps to task : 2 block traff

Step 1:
aws eks --region us-east-1 update-kubeconfig --name AWS-EKS



Step 2:
eksctl utils associate-iam-oidc-provider --region us-east-1  --cluster 
AWS-EKS   --approve

Step 3:
aws eks update-addon --cluster-name my-cluster --addon-name vpc-cni --addon-version v1.14.0-eksbuild.3 \
    --service-account-role-arn arn:aws:iam::123456789012:role/AmazonEKSVPCCNIRole \
    --resolve-conflicts PRESERVE --configuration-values '{"enableNetworkPolicy": "true"}'


step4:

kubectl edit configmap -n kube-system amazon-vpc-cni -o yaml

Add the following line to the data in the ConfigMap.
enable-network-policy-controller: "true"

kubectl edit daemonset -n kube-system aws-node
make sure:
     - args:
        - --enable-network-policy=true


aws ecr get-login-password \
        --region us-east-1 | docker login \
        --username AWS \
        --password-stdin 943330243877.dkr.ecr.us-east-1.amazonaws.com
        

brew install docker-buildx       
        
## docker push commands

docker buildx build --platform linux/amd64 -t hello-world-java:v1 .

docker tag hello-world-java:v1 943330243877.dkr.ecr.us-east-1.amazonaws.com/java-web-app:v1

docker tag hello-world-java:v1  943330243877.dkr.ecr.us-east-1.amazonaws.com/java-web-app:v1

docker push 943330243877.dkr.ecr.us-east-1.amazonaws.com/java-web-app:v1
docker push 943330243877.dkr.ecr.us-east-1.amazonaws.com/java-web-app:v1


aws ecr get-login-password --region <region>| docker login --username <username> --password-stdin <account_number>.dkr.ecr.<region>.amazonaws.com


aws ecr get-login-password \
        --region us-east-1 | docker login \
        --username AWS \
        --password-stdin 943330243877.dkr.ecr.us-east-1.amazonaws.com



aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json


eksctl create iamserviceaccount \
  --cluster=AWS-EKS \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::943330243877:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve


-----Pod Discovery:-----------
Pod-2 needs to discover the IP address of Pod-1. This can be done through the Kubernetes Service Discovery mechanism.

DNS Resolution:
The Pod-2 queries the Kubernetes DNS service to resolve the hostname of Pod-1 to its IP address. In Kubernetes, each service gets a DNS entry in the form of <service-name>.<namespace>.svc.cluster.local. So, if Pod-1 is part of the same namespace as Pod-2, Pod-2 can resolve Pod-1's IP address using its hostname.

Network Routing:
Once the IP address of Pod-1 is resolved, Pod-2 sends network packets to Pod-1's IP address. The network routing is handled by the underlying container network or network overlay solution used in the Kubernetes cluster.

Overlay Network (Optional):
If the cluster is using an overlay network (e.g., Flannel, Calico, or others), the network packets between Pod-1 and Pod-2 may traverse through the overlay network. These overlay networks create a virtual network that spans across the nodes in the cluster.

Node-to-Node Communication:
The network packets move between the nodes where Pod-1 and Pod-2 are running. This inter-node communication is facilitated by the underlying networking infrastructure of the cluster.

Pod Networking:
Finally, the network packets reach the node where Pod-1 is running, and they are delivered to Pod-1 through the Pod's networking interface.

Here's a simplified flow diagram:

                    +------------------+
                    | DNS Resolution   |
                    +------------------+
                               |
                               v
                    +------------------+
                    |  Network Routing |
                    +------------------+
                               |
                               v
                    +------------------+
                    | Overlay Network  |
                    +------------------+
                               |
                               v
                    +------------------+
                    | Inter-Node       |
                    | Communication    |
                    +------------------+
                               |
                               v
                    +------------------+
                    | Pod Networking   |
                    +------------------+


----------------Host java 3 tier applications ----------
aws eks --region us-east-1 update-kubeconfig --name AWS-EKS



eksctl utils associate-iam-oidc-provider --region us-east-1  --cluster 
AWS-EKS   --approve

terraform-eks % kubectl get nodes

NAME                         STATUS   ROLES    AGE    VERSION
ip-10-0-1-245.ec2.internal   Ready    <none>   111m   v1.28.3-eks-e71965b
ip-10-0-2-223.ec2.internal   Ready    <none>   111m   v1.28.3-eks-e71965b
ip-10-0-2-86.ec2.internal    Ready    <none>   3m3s   v1.28.3-eks-e71965b


in case minikube:
kubectl taint nodes control_panel key1=value1:NoSchedule 
ignore for eks:


how to check if its working:
https://medium.com/@aaloktrivedi/using-kubernetes-to-deploy-a-3-tier-containerized-application-infrastructure-9fbbbbc85ff6





--------java app----



kubectl label nodes ip-10-0-1-245.ec2.internal frontend
error: at least one label update is required
piyush@piyush-MacBook-Pro spring3hibernate % kubectl label nodes ip-10-0-1-245.ec2.internal app=frontend
node/ip-10-0-1-245.ec2.internal labeled
piyush@piyush-MacBook-Pro spring3hibernate % kubectl label nodes ip-10-0-1-202.ec2.internal  app=backend 
node/ip-10-0-2-223.ec2.internal labeled
piyush@piyush-MacBook-Pro spring3hibernate % kubectl label nodes ip-10-0-2-83.ec2.internal app=database


kubectl get nodes --show-labels

### how to predict ip range of pod 
The network is configured with weave.
 Check the weave pods logs using the command kubectl logs <weave-pod-name> weave -n kube-system and look for ipalloc-range.

 kubectl logs weave-net-b62dl weave -n kube-system | grep 'ipalloc-range'


 ## Taint vs affinity
 it promises that only pod with tolerance can be scheduled on the node:

 ie let say we put taint on node-1 =Blue
 and tolerance on pod-1= Blue 

 pod-1 can we scheduled at node-1

 but the catch is it can go to other nodes as well
 but node-1 will not accept any other pod without tolerance 

## Affinity 
if want pod-1 to be scheduled only on node-1 then we should use affinity which will force pod-1 to scheduled at Node-1 only.



### docker 
 sudo chmod 666 /var/run/docker.sock
 Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: