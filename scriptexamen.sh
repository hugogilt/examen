#!/bin/bash

# Nombre de la VPC
VPC_NAME="VPCExamen"

# Crear VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.1.0/24 --output json | jq -r '.Vpc.VpcId')
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME

# Crear subredes
declare -A DEPARTAMENTOS=( ["ingenieria"]="100" ["desarrollo"]="500" ["mantenimiento"]="20" ["soporte"]="250" )

for DEPT in "${!DEPARTAMENTOS[@]}"; do
    SUBNET_CIDR="192.168.1.$((RANDOM % 254 + 1))/28"
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --output json | jq -r '.Subnet.SubnetId')

    # Crear instancia EC2 para cada departamento
    INSTANCE_NAME="ec2-$DEPT"
    INSTANCE_TYPE="t2.micro"  # Puedes ajustar el tipo de instancia según tus necesidades

    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id ami-xxxxxxxxxxxxxxxxx \  # Especifica una AMI válida
        --subnet-id $SUBNET_ID \
        --instance-type $INSTANCE_TYPE \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
        --query 'Instances[0].InstanceId' \
        --output json)

    echo "Instancia $INSTANCE_NAME creada con ID: $INSTANCE_ID en la subred $SUBNET_ID"
done
