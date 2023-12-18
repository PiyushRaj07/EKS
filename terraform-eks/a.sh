#!/bin/bash

# Get the node names in your EKS cluster
NODES_STRING=$(kubectl get nodes -o=jsonpath='{.items[*].metadata.name}')

# Counter variable
count=1

# Iterate over each node directly
for node in $NODES_STRING; do
  echo "Node: $node"
  echo "Count: $count"  # Debug statement
  # Apply label to the current node for ns-$count
  kubectl label nodes "$node" ns=ns-$count --overwrite
  # Increment the counter
  ((count++))
done

