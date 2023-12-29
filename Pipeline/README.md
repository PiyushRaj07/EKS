# AWS CodePipeline CI/CD example
Terraform is an infrastructure-as-code (IaC) tool that helps you create, update, and version your infrastructure in a secure and repeatable manner.

The scope of this pattern is to provide a guide and ready to use terraform configurations to setup validation pipelines with end-to-end tests based on AWS CodePipeline, AWS CodeBuild, AWS CodeCommit and Terraform. 

The created pipeline uses the best practices for infrastructure validation and has the below stages

- validate - This stage focuses on terraform IaC validation tools and commands such as terraform validate, terraform format, tfsec, tflint and checkov
- plan - This stage creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.
- apply - This stage uses the plan created above to provision the infrastructure in the test account.
- destroy - This stage destroys the infrastructure created in the above stage.
Running these four stages ensures the integrity of the terraform configurations.



```
## Installation

#### Step 1: Clone this repository.

```shell
git clone $repo
```


#### Step 2: Update the variables in `examples/terraform.tfvars` based on your requirement. Make sure you ae updating the variables project_name, environment, source_repo_name, source_repo_branch, create_new_repo, stage_input and build_projects.

- If you are planning to use an existing terraform CodeCommit repository, then update the variable create_new_repo as false and provide the name of your existing repo under the variable source_repo_name
- If you are planning to create new terraform CodeCommit repository, then update the variable create_new_repo as true and provide the name of your new repo under the variable source_repo_name

#### Step 3: Update remote backend configuration as required

#### Step 4: Configure the AWS Command Line Interface (AWS CLI) where this IaC is being executed. For more information, see [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

#### Step 5: Initialize the directory. Run terraform init

#### Step 6: Start a Terraform run using the command terraform apply

Note: Sample terraform.tfvars are available in the examples directory. You may use the below command if you need to provide this sample tfvars as an input to the apply command.
```shell
terraform apply -var-file=./examples/terraform.tfvars
```

## Pre-Requisites

#### Step 1: You would get source_repo_clone_url_http as an output of the installation step. Clone the repository to your local.

git clone <source_repo_clone_url_http>

#### Step 2: Clone this repository.

```shell
git@github.com:aws-samples/aws-eks-accelerator-for-terraform.git
```
Note: If you don't have git installed, [install git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

#### Step 3: Copy the templates folder to the AWS CodeCommit sourcecode repository which contains the terraform code to be deployed.
```shell
cd examples/ci-cd/aws-codepipeline
cp -r templates $YOUR_CODECOMMIT_REPO_ROOT
```


#### Step 4: Update the variables in the template files with appropriate values and push the same.

#### Step 5: Trigger the pipeline created in the Installation step.

**Note1**: The IAM Role used by the newly created pipeline is very restrictive and follows the Principle of least privilege. Please update the IAM Policy with the required permissions. 
Alternatively, use the _**create_new_role = false**_ option to use an existing IAM role and specify the role name using the variable _**codepipeline_iam_role_name**_

**Note2**: If the **create_new_repo** flag is set to **true**, a new blank repository will be created with the name assigned to the variable **_source_repo_name_**. Since this repository will not be containing the templates folder specified in Step 3 nor any code files, the initial run of the pipeline will be marked as failed in the _Download-Source_ stage itself.

**Note3**: If the **create_new_repo** flag is set to **false** to use an existing repository, ensure the pre-requisite steps specified in step 3 have been done on the target repository.



