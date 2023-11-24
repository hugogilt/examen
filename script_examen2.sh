AWS_ID_GrupoSeguridad_EC2HUGOGILEXAMEN=$(
  aws ec2 create-security-group \
  --group-name 'SecGroupEC2HUGOGILEXAMEN' \
  --description 'Permitir conexiones SSH' \
  --output text
)

aws ec2 authorize-security-group-ingress \
--group-id $AWS_ID_GrupoSeguridad_EC2HUGOGILEXAMEN \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

aws ec2 run-instances \
--image-id ami-050406429a71aaa64 \
--count 1  \
--instance-type m1.small \
--key-name vockey \
--region us-east-1 \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EC2HUGOGILEXAMEN}]' \
--security-group-ids $AWS_ID_GrupoSeguridad_EC2HUGOGILEXAMEN

#version de GPT -------------------------

# Crear una VPC
AWS_ID_VPC=$(
  aws ec2 create-vpc \
  --cidr-block 192.168.1.0/24 \
  --output text
)

# Asignar un nombre a la VPC
aws ec2 create-tags \
  --resources $AWS_ID_VPC \
  --tags Key=Name,Value=CRUsystemVPC

# Crear subredes para cada departamento

# Nombre de la VPC
VPC_NAME="VPCExamen"

# Crear VPC
VPC_ID=$AWS_ID_VPC

# Crear subredes
declare -A SUBNETS=( ["Desarrollo"]="192.168.0.0/23" ["Soporte"]="192.168.2.0/24" ["Ingenieria"]="192.168.3.0/25" ["Mantenimiento"]="192.168.3.128/27" )

for SUBNET_NAME in "${!SUBNETS[@]}"; do
    SUBNET_CIDR=${SUBNETS[$SUBNET_NAME]}
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --output json | jq -r '.Subnet.SubnetId')

    aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=$SUBNET_NAME

    echo "Subred $SUBNET_NAME creada con ID: $SUBNET_ID"
done

  # Crear subred en la VPC
  AWS_ID_Subred=$(
    aws ec2 create-subnet \
    --vpc-id $AWS_ID_VPC \
    --cidr-block $SUBNET_CIDR \
    --output text
  )

  # Crear grupo de seguridad en la VPC
  AWS_ID_GrupoSeguridad=$(
    aws ec2 create-security-group \
    --group-name "SecGroup$DEP" \
    --description "Grupo de seguridad para $DEP" \
    --vpc-id $AWS_ID_VPC \
    --output text
  )

  # Autorizar el tráfico SSH en el grupo de seguridad
  aws ec2 authorize-security-group-ingress \
    --group-id $AWS_ID_GrupoSeguridad \
    --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

  # Crear instancia EC2 en la subred con el grupo de seguridad
  aws ec2 run-instances \
    --image-id ami-050406429a71aaa64 \
    --count 1 \
    --instance-type t2.micro \
    --key-name tu-key-name \
    --region us-east-1 \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=ec2-$DEP}]","ResourceType=subnet,Tags=[{Key=Name,Value=subnet-$DEP}]" \
    --security-group-ids $AWS_ID_GrupoSeguridad \
    --subnet-id $AWS_ID_Subred
done