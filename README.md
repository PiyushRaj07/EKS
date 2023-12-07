# EKS
EKS rootkit

if you cretae cluster and want to access for the first time :


eksctl utils associate-iam-oidc-provider --region us-east-1  --cluster  my-custom-networking-cluster --approve


aws eks --region us-east-1 update-kubeconfig --name my-custom-networking-cluster



Step 1: get node 

opstree@opstrees-MacBook-Pro ~ % kubectl get no  -o wide

output:
NAME                         STATUS   ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP      OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-1-243.ec2.internal   Ready    <none>   25m   v1.28.3-eks-e71965b   10.0.1.243    34.207.213.148   Amazon Linux 2   5.10.198-187.748.amzn2.x86_64   containerd://1.6.19
ip-10-0-2-145.ec2.internal   Ready    <none>   25m   v1.28.3-eks-e71965b   10.0.2.145    3.83.79.41       Amazon Linux 2   5.10.198-187.748.amzn2.x86_64   containerd://1.6.19


##cretae namespace:kubectl create namespace ns-1

create pod1:
opstree@opstrees-MacBook-Pro ~ % cat pod-1.yaml 
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
opstree@opstrees-MacBook-Pro ~ % kubectl get pod -o wide -n ns-1
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
opstree@opstrees-MacBook-Pro ~ % aws ec2 describe-vpcs --vpc-ids $vpc_id --query 'Vpcs[*].CidrBlockAssociationSet[*].{CIDRBlock: CidrBlock, State: CidrBlockState.State}' --out table

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
opstree@opstrees-MacBook-Pro ~ % new_subnet_id_1=$(aws ec2 create-subnet --vpc-id $vpc_id --availability-zone $az_1 --cidr-block 192.168.1.0/27 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-eks-custom-networking-vpc-PrivateSubnet01},{Key=kubernetes.io/role/internal-elb,Value=1}]' \
    --query Subnet.SubnetId --output text)
new_subnet_id_2=$(aws ec2 create-subnet --vpc-id $vpc_id --availability-zone $az_2 --cidr-block 192.168.1.32/27 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-eks-custom-networking-vpc-PrivateSubnet02},{Key=kubernetes.io/role/internal-elb,Value=1}]' \
    --query Subnet.SubnetId --output text)
opstree@opstrees-MacBook-Pro ~ % aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" \
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

in case there is no ping utility
kubectl exec -it pod-1 -n ns-1 -- apt-get update
kubectl exec -it pod-1 -n ns-1 -- apt-get install -y iputils-ping


how to block ns-1 traffice to ns-2

