## Depending upon the application you have to choose the right vpc architecture for this service.
### AWS VPC Infrastructure for EKS
## Overview

This Terraform configuration sets up an AWS VPC (eks_vpc) for an EKS cluster. It includes the creation of public and private subnets across multiple availability zones, an Internet Gateway for public subnet access, NAT Gateways for outbound traffic from private subnets, route tables, and Network ACLs.

## Components

VPC (eks_vpc): A virtual network dedicated to your AWS account.

Internet Gateway (eks_internet_gateway): A gateway attached to the VPC to allow communication between instances in the VPC and the internet.

Public Subnets (public_subnet_az1, public_subnet_az2): Subnets for resources that need to be accessible from the internet.

Private Subnets (private_subnet_az1, private_subnet_az2, private_subnet_az3, private_subnet_az4): Subnets for resources that don't require direct access to the internet.

NAT Gateways (nat_gw_az1, nat_gw_az2): Enable instances in private subnets to initiate outbound traffic to the internet.

Route Tables: Define rules to determine where network traffic from subnets is directed.

Network ACLs (main_network_acl, main_network_acl_privateA, main_network_acl_privateB): Act as a firewall for associated subnets, controlling inbound and outbound traffic.

## Prerequisites
1: Terraform installed on your machine.
2: An AWS account with necessary permissions to create the resources.
3: AWS CLI configured for access to your account.
 

## What is the security policy in terms of security group, acl which you are going to choose.
  ACL : for each subnet ie( subnet for db subnet  and application subnet )
  Allowing the acl_a (application )  access on port 3306 acl_b 
##  In terms of EKS, what is the current architecture and why you are going with this approach.

## Self-managed nodes
Self-managed nodes offer full control over your Amazon EC2 instances within an Amazon EKS cluster. You are in charge of managing, scaling, and maintaining the nodes, giving you total control over the underlying infrastructure. This option is suitable for users who need granular control and customization of their nodes and are ready to invest time in managing and maintaining their infrastructure


1: Launch template  
2: We have requirement of custom ami 
3: Custom metrics

