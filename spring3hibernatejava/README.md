
kubectl apply -f frontend-namespace.yaml, 
kubectl apply -f backend-namespace.yaml,
kubectl apply -f database-namespace.yaml

Node Selector:

kubectl apply -f frontend-pod.yaml

Network Connectivity:

kubectl apply -f frontend-service.yaml 
and 
kubectl apply -f database-service.yaml