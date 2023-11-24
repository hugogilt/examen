###############################################################################
#      Creación de una VPC y varias instancias EC2 Ubuntu Server 22.04
#      con IPs elásticas en AWS con AWS CLI
#
#      Utilizado para AWS Academy Learning Lab
###############################################################################

AWS_VPC_CIDR_BLOCK=192.168.0.0/22
AWS_Proyecto=DAW-Exam

echo "######################################################################"
echo "Creación de una VPC y varias instancias EC2 Ubuntu Server 22.04 "
echo "Se van a crear con los siguientes valores:"
echo "AWS_VPC_CIDR_BLOCK:    " $AWS_VPC_CIDR_BLOCK
echo "AWS_Proyecto:          " $AWS_Proyecto
echo "######################################################################"
echo "############## Crear VPC, Subredes #####################"
echo "######################################################################"
echo "Creando VPC..."

AWS_ID_VPC=$(aws ec2 create-vpc \
  --cidr-block $AWS_VPC_CIDR_BLOCK \
  --amazon-provided-ipv6-cidr-block \
  --query 'Vpc.{VpcId:VpcId}' \
  --output text)

## Habilitar los nombres DNS para la VPC
aws ec2 modify-vpc-attribute \
  --vpc-id $AWS_ID_VPC \
  --enable-dns-hostnames "{\"Value\":true}"

## Crear varias subredes con sus respectivas etiquetas
echo "Creando Subredes..."
declare -a AWS_ID_Subredes

# Definir las CIDR Blocks para las subredes
declare -a AWS_Subredes_CIDR_BLOCKS=("192.168.0.0/23" "192.168.2.0/24" "192.168.3.0/25" "192.168.3.128/27")

# Crear subredes y almacenar sus IDs en el array AWS_ID_Subredes
for CIDR_BLOCK in "${AWS_Subredes_CIDR_BLOCKS[@]}"; do
  SubnetId=$(aws ec2 create-subnet \
    --vpc-id $AWS_ID_VPC \
    --cidr-block $CIDR_BLOCK \
    --availability-zone us-east-1a \
    --query 'Subnet.{SubnetId:SubnetId}' \
    --output text)
  AWS_ID_Subredes+=($SubnetId)
done

## Habilitar la asignación automática de IPs públicas en las subredes públicas
for SubredId in "${AWS_ID_Subredes[@]}"; do
  aws ec2 modify-subnet-attribute \
    --subnet-id $SubredId \
    --map-public-ip-on-launch
done

###############################################################################
####################       UBUNTU SERVER     ##################################
###############################################################################

## Crear grupos de seguridad Ubuntu Server para cada subred
echo "########################### Ubuntu Server ############################"
echo "######################################################################"
declare -a AWS_ID_GruposSeguridad

# Crear grupos de seguridad y almacenar sus IDs en el array AWS_ID_GruposSeguridad
for SubredId in "${AWS_ID_Subredes[@]}"; do
  GrupoSeguridadId=$(aws ec2 create-security-group \
    --vpc-id $AWS_ID_VPC \
    --group-name $AWS_Proyecto-us-sg \
    --description "$AWS_Proyecto-us-sg" \
    --output text)

  echo "ID Grupo de seguridad de ubuntu para la subred $SubredId: " $GrupoSeguridadId

  ## Añadir reglas de seguridad al grupo de seguridad Ubuntu Server
  aws ec2 authorize-security-group-ingress \
    --group-id $GrupoSeguridadId \
    --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

  aws ec2 authorize-security-group-ingress \
    --group-id $GrupoSeguridadId \
    --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'

  aws ec2 authorize-security-group-ingress \
    --group-id $GrupoSeguridadId \
    --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 53, "ToPort": 53, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow DNS(TCP)"}]}]'

  aws ec2 authorize-security-group-ingress \
    --group-id $GrupoSeguridadId \
    --ip-permissions '[{"IpProtocol": "UDP", "FromPort": 53, "ToPort": 53, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow DNS(UDP)"}]}]'

  ## Añadir etiqueta al grupo de seguridad
  aws ec2 create-tags \
    --resources $GrupoSeguridadId \
    --tags "Key=Name,Value=$AWS_Proyecto-us-sg"
  
  AWS_ID_GruposSeguridad+=($GrupoSeguridadId)
done

###############################################################################
## Crear instancias EC2 (con una imagen de Ubuntu 22.04) para cada subred
###############################################################################
echo ""
echo "Creando instancias EC2 Ubuntu  ##################################"
AWS_AMI_Ubuntu_ID=ami-052efd3df9dad4825

declare -a AWS_ID_Instancias

# Crear instancias y almacenar sus IDs en el array AWS_ID_Instancias
for ((i=0; i<${#AWS_ID_Subredes[@]}; i++)); do
  Departamento=""
  case $i in
    0)
      Departamento="Desarrollo"
      ;;
    1)
      Departamento="Soporte"
      ;;
    2)
      Departamento="Ingeniería"
      ;;
    3)
      Departamento="Mantenimiento"
      ;;
    *)
      Departamento="Desconocido"
      ;;
  esac

  AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AWS_AMI_Ubuntu_ID \
    --instance-type t2.micro \
    --key-name vockey \
    --monitoring "Enabled=false" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$Departamento'-EC2}]' \
    --security-group-ids ${AWS_ID_GruposSeguridad[$i]} \
    --subnet-id ${AWS_ID_Subredes[$i]} \
    --query 'Instances[0].InstanceId' \
    --output text)
  AWS_ID_Instancias+=($AWS_EC2_INSTANCE_ID)
done

