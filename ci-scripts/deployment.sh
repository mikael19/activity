#!/bin/bash

set +ex

#@--- install kubectl and doctl ---@#
install_kubectl_doctl() {
    if [[ $TRAVIS_BRANCH == "dev" ]] || \
        [[ $TRAVIS_BRANCH == "ACT-693" ]]; then
        echo "++++++++++++ install kubectl ++++++++++++"
        curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

        # Make downloaded binary executable
        chmod +x ./kubectl

        # Add binary to path
        sudo mv ./kubectl /usr/local/bin/kubectl

        # Check the version 
        kubectl version --client

        # Install digital ocean cli tool
        sudo snap install doctl
        sudo snap connect doctl:kube-config

        sudo apt-get install gettext -y

        mkdir /home/travis/.kube
    fi
}

#@--- Authorize kubectl to cluster ---@#
auth_kubectl_cluster() {
    # Authenticate kubectl to the cluster
    if [[ $TRAVIS_BRANCH == "dev" ]] || \
        [[ $GITHUB_REF == "refs/heads/dev" ]] || \
        [[ $TRAVIS_BRANCH == "ACT-693" ]]; then
        doctl -t $SERVICE_ACCESS_TOKEN kubernetes cluster kubeconfig save $CLUSTER_NAME
        doctl auth init -t $SERVICE_ACCESS_TOKEN
        kubectl create namespace $APPLICATION_ENV || echo "++++++ Namespace Exists ++++++"
        kubectl create namespace ingress-nginx || echo "++++++ Namespace ingress-nginx Exists ++++++"
    fi
    
    # fetch cluster nodes
    kubectl get nodes

    echo "+++ Kubectl installed and configured to the cluster +++++"
}

#@--- Function to deploy the app ---@#
deploy_app() {
    echo "-------- deploy application -------------"

    echo "-------- generate secret for dockerhub -----------"
    docker login -p=$DOCKER_HUB_PASSWD -u=$DOCKER_HUB_USERNM
    kubectl create secret generic regcred \
        --from-file=.dockerconfigjson=$FILE_PATH \
        --type=kubernetes.io/dockerconfigjson -n $APPLICATION_ENV

    if [[ $TRAVIS_BRANCH == "dev" ]]  || \
        [[ $GITHUB_REF == "refs/heads/dev" ]] || \
        [[ $TRAVIS_BRANCH == "ACT-693" ]]; then
        echo "------- generate deployfiles --------------"
        envsubst < ./deployment_files/deployment > deployment.yaml
        envsubst < ./deployment_files/service > service.yaml
        envsubst < ./deployment_files/autoscaler > autoscaler.yaml
        envsubst < ./deployment_files/ingress-config > ingress-config.yaml
        envsubst < ./deployment_files/cert-config/cert-issuer > cert-issuer.yaml
        envsubst < ./deployment_files/cert-config/cert-secret > cert-secret.yaml
        envsubst < ./deployment_files/cert-config/certificate > certificate.yaml

        echo "+++++++  make deployments with kubectl +++++++"
        kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts
        kubectl apply -f deployment_files/man.yaml 
        kubectl apply --validate=false -f deployment_files/cert-config/cert-manager-0.12.0.yaml
        kubectl apply --validate=false -f deployment_files/metrics-server.yaml
        sleep 60

        kubectl apply -f deployment_files/ingress-service.yaml 
        kubectl apply -f cert-secret.yaml  
        kubectl apply --validate=false -f cert-issuer.yaml
        kubectl apply --validate=false -f certificate.yaml
        kubectl apply -f deployment.yaml  
        kubectl apply -f service.yaml
        kubectl apply -f autoscaler.yaml 
        kubectl apply -f ingress-config.yaml   
        echo "--------- deployment made !! ----------------"
    fi
}

#@--- Function to replace some key variables ---@#
replace_variables() {
    if [[ $TRAVIS_BRANCH == "ACT-693" ]]; then
        export APPLICATION_ENV=${APPLICATION_ENV_PROD}
        export HOST_DOMAIN=${HOST_DOMAIN_PROD}
        export CLUSTER_NAME=${CLUSTER_NAME_PROD}

    fi
}

#@--- Main Function ---@#
main() {

    if [[ $TRAVIS_EVENT_TYPE != "pull_request" ]]; then
        #@--- Run install and setup function ---@#
        install_kubectl_doctl

        #@--- run the replace function ---@#
        replace_variables

        #@--- Run the setup function ---@#
        auth_kubectl_cluster

        #@--- Run deployment functio ---@#
        deploy_app
    fi

}

#@--- Run the main function ---@#
main
