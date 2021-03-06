#!/bin/bash

# Copyright 2020 Red Hat Inc.

# Parameters
# -t Runs a test, but does not perform andy actions


CLEAN_RESOURCES=0
if [ "$?" == "-t" ]; then
    echo "Test run ONLY."
    CLEAN_RESOURCES=1
fi


echo "Continuing to execute this script will destroy the following \"managed\" Openshift clusters:"
oc get clusterDeployments --all-namespaces
echo
echo "If you would like to proceed with cleanup, type: DESTROY"
read -r DESTROY_YES
if [ "${DESTROY_YES}" != "DESTROY" ]; then
  echo "You must type DESTROY to clean up the Hive deployed clusters"
  exit 1
fi
for clusterName in `oc get clusterDeployments --all-namespaces --ignore-not-found | grep -v "NAMESPACE" | awk '{ print $1 }'`; do
    echo "Destroying ${clusterName}"
    if [ $CLEAN_RESOURCES ]; then
        oc -n ${clusterName} delete clusterDeployment ${clusterName} --wait=false
        sleep 10
        podName=`oc -n ${clusterName} get pods | grep uninstall | awk '{ print $1 }'`
        oc -n ${clusterName} logs ${podName} -f
    fi
done

echo "Detaching imported clusters"
for clusterName in `oc get clusters --all-namespaces --ignore-not-found | grep -v "NAMESPACE" | awk '{ print $1 }'`; do
    printf " Detaching cluster ${clusterName}\n  "
    if [ $CLEAN_RESOURCES ]; then
        oc -n ${clusterName} delete cluster ${clusterName}
        printf "  "  #Spacing
        oc delete namespace ${clusterName} --wait=false
    fi
done

# Stage2, 2nd pass
echo "Second pass cleaning, by endpointConfig"
for clusterName in `oc get endpointconfig --all-namespaces --ignore-not-found | grep -v "NAMESPACE" | awk '{ print $1 }'`; do
    printf " Detaching cluster ${clusterName}\n  "
    if [ $CLEAN_RESOURCES ]; then
        oc -n ${clusterName} delete cluster ${clusterName}
        printf "  "  #Spacing
        oc delete namespace ${clusterName} --wait=false
    fi
done

echo "Done!"

