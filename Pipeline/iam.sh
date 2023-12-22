# Export your AWS Account(To get your aws account id run the following command aws sts get-caller-identity --query Account --output text)
export ACCOUNT_ID=<aws account id>

# Set the Trust Policy
TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"

# Create IAM Role for CodeBuild to Interact with EKS
aws iam create-role --role-name CodeBuildEKSRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'

# Create an Inline Policy with eks:Describe permission and redirect the output to eksdescribe.json
echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > /tmp/eksdescribe.json

# Add this Inline Policy to the IAM Role CodeBuildEKSRole
aws iam put-role-policy --role-name CodeBuildEKSRole --policy-name eks-describe-policy --policy-document file:///tmp/eksdescribe.json