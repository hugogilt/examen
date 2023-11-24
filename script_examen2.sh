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
declare -A DEPARTAMENTOS=( ["Ingenieria"]="100" ["Desarrollo"]="500" ["Mantenimiento"]="20" ["Soporte"]="250" )

for DEP in "${!DEPARTAMENTOS[@]}"; do
  SUBNET_CIDR="192.168.1.${RANDOM%255}/28"  # Puedes ajustar el rango de direcciones de subred según sea necesario

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