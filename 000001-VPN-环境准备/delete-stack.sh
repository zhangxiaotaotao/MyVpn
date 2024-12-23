#!/bin/bash

# 切换到脚本所在目录
cd "$(dirname "$0")"

# 设置必要的变量
STACK_NAME="zjt-test"
REGION="ap-southeast-1"

# 开始删除 Stack
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
echo "开始删除 Stack: $STACK_NAME"

# 循环检查删除状态
while true; do
    STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].StackStatus" --output text 2>&1)

    if [[ "$STATUS" == *"DELETE_COMPLETE"* ]]; then
        echo "Stack 删除完成: $STACK_NAME"
        break
    elif [[ "$STATUS" == *"DELETE_FAILED"* ]]; then
        echo "Stack 删除失败: $STACK_NAME"
        break
    elif [[ "$STATUS" == *"ValidationError"* && "$STATUS" == *"does not exist"* ]]; then
        echo "Stack $STACK_NAME 不存在，可能已成功删除"
        break
    else
        echo "当前状态: $STATUS"
    fi

    sleep 5  # 每隔 5 秒检查一次
done