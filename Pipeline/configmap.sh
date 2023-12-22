# Check the aws-auth configmap 
kubectl get configmap aws-auth -o yaml -n kube-system

# Export your AWS Account(To get your aws account id run the following command aws sts get-caller-identity --query Account --output text)
export ACCOUNT_ID=<aws account id>

# Set the ROLE value
ROLE="    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/CodeBuildEKSRole\n      username: build\n      groups:\n        - system:masters"

# Get the current aws-auth configMap data and add new role to it
kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/auth-patch.yml

# Patch the aws-auth configmap with new role
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/auth-patch.yml)"