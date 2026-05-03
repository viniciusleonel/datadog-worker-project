#!/bin/bash

echo "🚀 Criando recursos no LocalStack..."

REGION=us-east-1

# =========================
# 🔹 SNS
# =========================
TOPIC_ARN=$(awslocal sns create-topic \
  --name my-topic \
  --region $REGION \
  --query 'TopicArn' \
  --output text)

echo "📢 Topic criado: $TOPIC_ARN"

# =========================
# 🔹 DLQs
# =========================
echo "💀 Criando DLQs..."

DLQ_1_URL=$(awslocal sqs create-queue \
  --queue-name worker-queue-1-dlq \
  --region $REGION \
  --query 'QueueUrl' \
  --output text)

DLQ_2_URL=$(awslocal sqs create-queue \
  --queue-name worker-queue-2-dlq \
  --region $REGION \
  --query 'QueueUrl' \
  --output text)

DLQ_1_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $DLQ_1_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

DLQ_2_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $DLQ_2_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

echo "💀 DLQs criadas"

# =========================
# 🔹 Filas principais com DLQ
# =========================
echo "📬 Criando filas principais com DLQ..."

QUEUE_1_URL=$(awslocal sqs create-queue \
  --queue-name worker-queue-1 \
  --region $REGION \
  --attributes "{
    \"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_1_ARN\\\",\\\"maxReceiveCount\\\":\\\"5\\\"}\",
    \"VisibilityTimeout\":\"60\"
  }" \
  --query 'QueueUrl' \
  --output text)

QUEUE_2_URL=$(awslocal sqs create-queue \
  --queue-name worker-queue-2 \
  --region $REGION \
  --attributes "{
    \"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_2_ARN\\\",\\\"maxReceiveCount\\\":\\\"5\\\"}\",
    \"VisibilityTimeout\":\"60\"
  }" \
  --query 'QueueUrl' \
  --output text)

echo "📬 Filas criadas com DLQ"

# =========================
# 🔹 ARNs das filas principais
# =========================
QUEUE_1_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $QUEUE_1_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

QUEUE_2_ARN=$(awslocal sqs get-queue-attributes \
  --queue-url $QUEUE_2_URL \
  --attribute-names QueueArn \
  --query 'Attributes.QueueArn' \
  --output text)

# =========================
# 🔹 Subscriptions SNS → SQS
# =========================
echo "🔗 Criando subscriptions..."

awslocal sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $QUEUE_1_ARN

awslocal sns subscribe \
  --topic-arn $TOPIC_ARN \
  --protocol sqs \
  --notification-endpoint $QUEUE_2_ARN

# =========================
# 🔹 Policy para permitir SNS → SQS
# =========================
echo "🔐 Configurando permissões..."

POLICY_QUEUE_1=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "sqs:SendMessage",
    "Resource": "$QUEUE_1_ARN",
    "Condition": {
      "ArnEquals": {
        "aws:SourceArn": "$TOPIC_ARN"
      }
    }
  }]
}
EOF
)

POLICY_QUEUE_2=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "sqs:SendMessage",
    "Resource": "$QUEUE_2_ARN",
    "Condition": {
      "ArnEquals": {
        "aws:SourceArn": "$TOPIC_ARN"
      }
    }
  }]
}
EOF
)

awslocal sqs set-queue-attributes \
  --queue-url $QUEUE_1_URL \
  --attributes Policy="$POLICY_QUEUE_1"

awslocal sqs set-queue-attributes \
  --queue-url $QUEUE_2_URL \
  --attributes Policy="$POLICY_QUEUE_2"

echo "✅ Permissões configuradas"

# =========================
# 🔁 Loop de envio
# =========================
while true; do
  echo "📨 Enviando mensagem..."

  awslocal sns publish \
    --topic-arn $TOPIC_ARN \
    --message "{\"event\":\"order_created\",\"timestamp\":\"$(date)\"}"

  sleep 60
done