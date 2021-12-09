#!/bin/bash

cluster_name="marsci"
logs="tekton.log"

cluster_exist=$(kind get clusters | grep $cluster_name)

if [ ! -z "$cluster_exist" ]; then
  echo "Cluster $cluster_name já existe, deleta (y/n)?"
  read resp
  if [ $resp = 'y' ]; then
     echo "Deletando o kubernetes"
     kind delete cluster --name $cluster_name -q
  fi
fi   

echo "Instalando o kubernetes"
kind create cluster --name $cluster_name -q
#kubectl cluster-info --context kind-$cluster_name 

echo "Instalando o Tekton"
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml 2>&1 > $logs
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml 2>&1 >> $logs
kubectl apply -f configs/metrics.yaml 2>&1 > $logs

echo -n "Iniciando o TekTon"
x=0
while [ $x != 3 ]
do
    x=$(kubectl -n tekton-pipelines get pods --field-selector=status.phase=Running -o jsonpath='{.items[*].status.phase}' | wc -w)
    sleep 10
    echo -n "."
done 

echo "Done."

kubectl -n tekton-pipelines port-forward svc/tekton-dashboard 9097:9097  >> $logs 2>&1 &
kubectl -n tekton-pipelines port-forward svc/tekton-pipelines-controller 9090:9090 >> $logs 2>&1 &

echo "Dashboard: http://localhost:9097"
echo "Metrics: http://localhost:9090/metrics"
echo "MarsCI Configurado."