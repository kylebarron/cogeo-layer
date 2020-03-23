#!/bin/bash
# Highly inpired by https://github.com/keithrozario/Klayers/tree/master/scripts/deploy_with_docker
echo "-------------------"
echo "Deploy Lambda Layer"
echo "-------------------"

LAYER_NAME=$1
GDAL_VERSION=$2
PYTHON_VERSION=$3

AWS_REGIONS=(
    eu-central-1
    us-east-1 us-east-2
    us-west-1 us-west-2
)

PYTHON_VERSION_NODOT="${PYTHON_VERSION//.}"
GDAL_VERSION_NODOT="${GDAL_VERSION//.}"

LAYER_RUNTIME=python${PYTHON_VERSION}
LNAME=gdal${GDAL_VERSION_NODOT}-py${PYTHON_VERSION_NODOT}-${LAYER_NAME}
LAYER_DESC="Lambda Layer - ${LAYER_RUNTIME}"

LOCAL_LNAME=gdal${GDAL_VERSION}-py${PYTHON_VERSION}-${LAYER_NAME}.zip
LAYER_HASH=$(sha256sum ${LOCAL_LNAME} | awk '{print $1}')

echo "Deploying ${LNAME}"
for AWS_REGION in "${AWS_REGIONS[@]}"; do
    # Get hash of latest version
    echo "List Layer in ${AWS_REGION}"
    LIST_LAYERS=$(aws lambda list-layer-versions --compatible-runtime ${LAYER_RUNTIME} --layer-name ${LNAME} --region ${AWS_REGION})
    AWS_LAYER_VERSION=$(jq -r '.LayerVersions[0].Version' <<< "${LIST_LAYERS}")

    if [[ $AWS_LAYER_VERSION = "null" ]];
    then
        AWS_LAYER_DESC="dummy"
        AWS_LAYER_VERSION=1
    else
        AWS_LAYER=$(aws lambda get-layer-version --version-number ${AWS_LAYER_VERSION} --layer-name ${LNAME} --region ${AWS_REGION})
        AWS_LAYER_DESC=$(jq -r '.Description' <<< "${AWS_LAYER}")
		AWS_LAYER_SHA=$(echo "${AWS_LAYER_DESC}" | awk '{print $8}')

        # increment version
        let "AWS_LAYER_VERSION++"
    fi

    if [[ $LAYER_HASH != $AWS_LAYER_SHA ]];
    then
        echo "Publishing"
        aws lambda publish-layer-version \
        --region $AWS_REGION \
        --layer-name $LNAME \
        --zip-file fileb://$LOCAL_LNAME \
        --description "${LAYER_DESC} | ${LAYER_HASH}" \
        --compatible-runtimes ${LAYER_RUNTIME} \
        --license-info MIT \
        --cli-connect-timeout 6000

        aws lambda add-layer-version-permission \
            --region ${AWS_REGION} \
            --layer-name ${LNAME} \
            --statement-id make_public \
            --version-number ${AWS_LAYER_VERSION} \
            --principal '*' \
            --action lambda:GetLayerVersion
    fi
done
