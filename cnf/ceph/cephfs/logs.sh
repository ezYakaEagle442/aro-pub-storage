#!/bin/bash

CONTAINER_NAME=csi-cephfsplugin
POD_NAME=$(oc get pods -l app=$CONTAINER_NAME -n $CSI_NAMESPACE -o=name | head -n 1)

function get_pod_status() {
	echo -n "$(oc get "$POD_NAME" -n $CSI_NAMESPACE -o jsonpath="{.status.phase}")"
}

while [[ "$(get_pod_status)" != "Running" ]]; do
	sleep 1
	echo "Waiting for $POD_NAME (status $(get_pod_status))"
done

kubectl logs -f "$POD_NAME" -c "$CONTAINER_NAME"
