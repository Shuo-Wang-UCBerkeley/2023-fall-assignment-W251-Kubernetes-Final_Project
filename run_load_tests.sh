#!/bin/bash

# Desired pod count
DESIRED_COUNT=2

NAMESPACE='wshuo87'

# List of cache rates
cache_rates=(0 0.05 0.1 0.2 0.4 0.6 0.8 0.9 0.95 1.0)

# Loop through each cache rate and 4run load.js
for rate in "${cache_rates[@]}"; do
    echo "Running load.js with cache rate: $rate"
    CACHE_RATE=$rate k6 run load.js

    # Loop until the number of pods equals the desired count
    while true; do
        # Get the current number of pods (excluding the header line)
        CURRENT_COUNT=$(expr $(kubectl get pods -n $NAMESPACE | wc -l) - 2)

        # Check if current count matches the desired count
        if [ "$CURRENT_COUNT" -eq "$DESIRED_COUNT" ]; then
            echo "Number of pods is now $DESIRED_COUNT." 
            break
        else
            echo "Waiting for the number of pods to be $DESIRED_COUNT. Current count: $CURRENT_COUNT" 
            sleep 20 # Wait for 5 seconds before rechecking
        fi 
    done
done

# #!/bin/bash
# # Define the namespace and the base URL
# NAMESPACE='wshuo87'
# BASE_URL="https://${NAMESPACE}.mids255.com"

# # Define the cache rates to test
# CACHE_RATES=(0 0.2 0.4 0.6 0.8 1.0)

# # Function to check the number of running pods and wait until there's only one
# wait_for_single_pod() {
#     while true; do
#         # Get the count of running pods
#         # RUNNING_PODS=$(kubectl get pods -n ${NAMESPACE} -l app=lab4 --field-selector=status.phase=Running | grep -c ^)
#         RUNNING_PODS=$(kubectl get pods -n ${NAMESPACE} -l app=lab4 --field-selector=status.phase=Running --no-headers | wc -l)

#         # Print the current number of running pods
#         echo "Current number of running pods: $RUNNING_PODS"

#         # If only one pod is running, break the loop
#         if [[ "$RUNNING_PODS" == "1" ]]; then
#             break
#         fi
        
#         # Otherwise, sleep for a bit before checking again
#         # echo "Waiting for running pods to scale down to 1..."
#         sleep 10
#     done
# }

# # Loop through each cache rate value
# for CACHE_RATE in "${CACHE_RATES[@]}"; do
#     # Replace the CACHE_RATE value in the load.js file
#     sed -i '' "s/const CACHE_RATE = .*/const CACHE_RATE = ${CACHE_RATE}/" load.js

#     # Run the load test
#     k6 run load.js

#     # Wait until the number of running pods is 1 before continuing
#     wait_for_single_pod
# done