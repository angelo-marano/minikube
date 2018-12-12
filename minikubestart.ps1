Function Test-FAVMSwitchexistence
{
    Param(
        [string]$VMSwitchname
    )
        $Item = (Get-VMSwitch | Where-Object -Property Name -EQ -Value $VMSwitchname).count
        If($Item -eq '1'){Return $true}else{Return $false}
}

#Set-PSDebug -Trace 1
Invoke-WebRequest -uri https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-windows-amd64.exe -OutFile minikube.exe
Invoke-WebRequest -uri https://storage.googleapis.com/kubernetes-release/release/v1.11.2/bin/windows/amd64/kubectl.exe -OutFile kubectl.exe

$TARGET_DIR = Join-Path -Path $Env:Programfiles -ChildPath "Minikube"
$MINKUBE_USR_DIR = Join-Path -Path $Env:USERPROFILE -ChildPath ".minikube"

if((Test-Path -Path $MINKUBE_USR_DIR))
{
    Remove-Item –path $MINKUBE_USR_DIR –recurse
}

New-Item -ItemType directory -Path $TARGET_DIR
Copy-Item minikube.exe -Destination $TARGET_DIR
Copy-Item kubectl.exe -Destination $TARGET_DIR

if(!(Test-FAVMSwitchexistence -VMSwitchname ExternalSwitch))
{
    $net = Get-NetAdapter -Name 'Wi-Fi 2'
    New-VMSwitch -Name "ExternalSwitch" -AllowManagementOS $True -NetAdapterName $net.Name
}

minikube config set vm-driver hyperv
minikube config set hyperv-virtual-switch ExternalSwitch
minikube config set memory 2048
minikube config set cpus 4

minikube start --v=7 --alsologtostderr
minikube addons enable heapster
minikube addons enable ingress

helm init
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install --name kubeapps --namespace kubeapps bitnami/kubeapps

kubectl create serviceaccount kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator

.\kubeapptoken.cmd

$POD_NAME=(kubectl get pods --namespace kubeapps -l "app=kubeapps" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace kubeapps $POD_NAME 8080:8080


