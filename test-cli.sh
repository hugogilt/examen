#!/bin/bash

# Configuración inicial
region="us-east-1"
vpc_cidr_block="192.168.0.0/22"
subnet_cidr_blocks=("192.168.0.0/23" "192.168.2.0/24" "192.168.3.0/25" "192.168.3.128/27")
department_names=("ingenieria" "desarrollo" "mantenimiento" "soporte")

# Crear VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr_block --amazon-provided-ipv6-cidr-block --query 'Vpc.VpcId' --output text --region $region)
echo "VPC creada con ID: $vpc_id"

# Habilitar la resolución DNS y asignar un nombre a la VPC
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}" --region $region
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}" --region $region
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=CRUsystemVPC --region $region

# Crear subredes y máquinas EC2
for ((i=0; i<${#subnet_cidr_blocks[@]}; i++)); do
    subnet_cidr=${subnet_cidr_blocks[$i]}
    department_name=${department_names[$i]}
    
    # Crear subred
    subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet_cidr --availability-zone ${region}a --query 'Subnet.SubnetId' --output text --region $region)
    echo "Subred ($department_name) creada con ID: $subnet_id"
    
    # Crear máquina EC2
    instance_id=$(aws ec2 run-instances --image-id ami-0230bd60aa48260c6 --instance-type t2.micro --subnet-id $subnet_id --query 'Instances[0].InstanceId' --output text --region $region)
    echo "Máquina EC2 ($department_name) creada con ID: $instance_id"
    
    # Asignar nombre a la máquina EC2
    aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=ec2-$department_name --region $region
done

echo "Script completado exitosamente"
