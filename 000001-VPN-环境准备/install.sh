#!/bin/bash

# 切换到脚本所在目录
cd "$(dirname "$0")"

cp ../000000-VPN-资源/zjt-test.pem ./
chmod 400 zjt-test.pem

# 设置必要的变量
STACK_NAME="zjt-test"
TEMPLATE_FILE="zjt-test.yml"
INSTANCE_TYPE="t2.medium"
KEY_NAME="zjt-test"
REGION="ap-southeast-1"
AMI_NAME="al2023-ami-2023.6.20241111.0-kernel-6.1-x86_64"
EC2_IMAGE_ID=$(aws ec2 describe-images --filters "Name=name,Values=$AMI_NAME" "Name=state,Values=available" --query "Images[0].ImageId" --output text --region $REGION)

echo "EC2_IMAGE_ID: $EC2_IMAGE_ID"

# 创建CloudFormation堆栈
aws cloudformation create-stack \
    --region $REGION \
    --stack-name $STACK_NAME \
    --template-body file://$TEMPLATE_FILE \
    --parameters ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE \
                 ParameterKey=KeyName,ParameterValue=$KEY_NAME \
                 ParameterKey=EC2ImageId,ParameterValue=$EC2_IMAGE_ID \
    --capabilities CAPABILITY_NAMED_IAM \
    > /dev/null 2>&1

# 等待堆栈创建完成
echo "⏳ 等待堆栈创建完成"
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION
echo "✅ 堆栈创建完成"

echo "🔍 获取实例ID"
NODE_ID=$(aws cloudformation describe-stack-resource --stack-name $STACK_NAME --region $REGION --logical-resource-id Node --query 'StackResourceDetail.PhysicalResourceId' --output text)

echo "🔍 获取实例私有IP"
NODE_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $NODE_ID --region $REGION --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

echo "🔍 获取实例公网IP地址"
NODE_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $NODE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "🔍 获取实例公网DNS地址"
NODE_PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $NODE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicDnsName' --output text)

# 输出实例信息到文件
echo "Writing instance information to .instance_information"
cat > ../.zjt_test_instance_information <<EOL
NODE_ID=${NODE_ID}
NODE_PRIVATE_IP=${NODE_PRIVATE_IP}
NODE_PUBLIC_IP=${NODE_PUBLIC_IP}
NODE_PUBLIC_DNS=${NODE_PUBLIC_DNS}
EOL

echo "==================================================================================="
echo "==============================INSTANCES INFORMATION👇=============================="
echo "==================================================================================="
echo "node instance:"
echo "    id: $NODE_ID"
echo "    private ip is: $NODE_PRIVATE_IP"
echo "    public ip is: $NODE_PUBLIC_IP"
echo "    public dns is: $NODE_PUBLIC_DNS"
echo "==================================================================================="
echo "==============================INSTANCES INFORMATION👆=============================="
echo "==================================================================================="

rm -rf zjt-test.pem

echo "sudo -E ssh -i zjt-test.pem ec2-user@$NODE_PUBLIC_IP"
echo "VPN实例配置完成！"