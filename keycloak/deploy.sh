#!/bin/bash

export KEYCLOAK_ADMIN_USERNAME_B64=""
export KEYCLOAK_ADMIN_PASSWORD_B64=""
export KEYCLOAK_DB_USERNAME_B64=""
export KEYCLOAK_DB_PASSWORD_B64=""
export KEYCLOAK_DB_HOST_B64=""
export KEYCLOAK_CERT_B64=""
export KEYCLOAK_CERT_PRIVATE_KEY_B64=""
export CA_CERT_PATH=""
export CA_CERT_PRIVATE_KEY_PATH=""

if [[ -z "$KEYCLOAK_ADMIN_USERNAME_B64" || 
	  -z "$KEYCLOAK_ADMIN_PASSWORD_B64" || 
	  -z "$KEYCLOAK_DB_USERNAME_B64" || 
	  -z "$KEYCLOAK_DB_PASSWORD_B64" || 
	  -z "$KEYCLOAK_DB_HOST_B64" || 
	  -z "$KEYCLOAK_CERT_B64" || 
	  -z "$KEYCLOAK_CERT_PRIVATE_KEY_B64" || 
	  -z "$CA_CERT_PATH" || 
	  -z "$CA_CERT_PRIVATE_KEY_PATH" 
]]; then
	echo "ERROR: Environment variables not set"
	exit 1
fi

set -x
							
sed -i "s/<KEYCLOAK_ADMIN_USERNAME>/$KEYCLOAK_ADMIN_USERNAME_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_ADMIN_PASSWORD>/$KEYCLOAK_ADMIN_PASSWORD_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_DB_USERNAME>/$KEYCLOAK_DB_USERNAME_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_DB_PASSWORD>/$KEYCLOAK_DB_PASSWORD_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_DB_HOST>/$KEYCLOAK_DB_HOST_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_CERT>/$KEYCLOAK_CERT_B64/g" secret.yaml
sed -i "s/<KEYCLOAK_CERT_PRIVATE_KEY>/$KEYCLOAK_CERT_PRIVATE_KEY_B64/g" secret.yaml

cat secret.yaml

cp $CA_CERT_PATH .
cp $CA_CERT_PRIVATE_KEY_PATH .

echo "$DOCKER_PASSWORD" | helm registry login $DOCKER_REGISTRY --username $DOCKER_USERNAME --password-stdin

helm package helm --app-version=1.0.0 --version=1.0.0

kubectl delete secret auth.topfilms.io-tls --namespace keycloak
kubectl create secret tls auth.topfilms.io-tls --cert=cert.pem --key=key.pem --namespace keycloak

rm cert.pem
rm key.pem

kubectl apply --filename secret.yaml --namespace keycloak

helm upgrade keycloak keycloak-1.0.0.tgz --version 1.0.0 --install --atomic --debug --history-max=3 --namespace keycloak --set image.tag=26.0.2 --timeout 10m0s

rm keycloak-1.0.0.tgz

git restore secret.yaml
git restore deploy.sh