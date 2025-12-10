#!/bin/bash
set -euo pipefail
export AWS_PAGER=""

# === Variablen ===
REGION="us-east-1"
ZIP_FILE="FaceRecognitionLambda.zip"
ROLE="LabRole"
HANDLER="FaceRecognitionLambda::FaceRecognitionLambda.Function::Handler"
TEST_IMAGE="Test.jpg"

# === Eindeutige Ressourcen-Namen ===
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TS=$(date -u +"%Y%m%d%H%M%S")
SHORTHEX=$(openssl rand -hex 4)

IN_BUCKET="face-recognition-in-${ACCOUNT_ID}-${TS}-${SHORTHEX}"
OUT_BUCKET="face-recognition-out-${ACCOUNT_ID}-${TS}-${SHORTHEX}"
LAMBDA_NAME="FaceRecognitionFunction_${ACCOUNT_ID}_${TS}_${SHORTHEX}"

echo "=== Ressourcen-Namen ==="
echo "IN_BUCKET: $IN_BUCKET"
echo "OUT_BUCKET: $OUT_BUCKET"
echo "LAMBDA: $LAMBDA_NAME"
echo ""

# === 1️⃣ S3 Buckets erstellen ===
echo "Erstelle S3 Buckets..."
aws s3 mb s3://$IN_BUCKET --region $REGION
aws s3 mb s3://$OUT_BUCKET --region $REGION

# === 2️⃣ Lambda Funktion erstellen ===
echo "Erstelle Lambda-Funktion..."
aws lambda create-function \
  --function-name "$LAMBDA_NAME" \
  --runtime dotnet8 \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE}" \
  --handler "$HANDLER" \
  --zip-file fileb://$ZIP_FILE \
  --timeout 30 \
  --memory-size 512

# === Warte auf aktive Lambda-Funktion ===
echo "Warte, bis Lambda aktiv ist..."
while true; do
    STATE=$(aws lambda get-function --function-name "$LAMBDA_NAME" --query 'Configuration.State' --output text --no-paginate)
    if [ "$STATE" == "Active" ]; then
        echo "Lambda ist aktiv."
        break
    fi
    echo "Lambda Status: $STATE. Warte 5 Sekunden..."
    sleep 5
done

# === 3️⃣ Berechtigung für S3 hinzufügen ===
echo "Füge Lambda Berechtigung für S3 hinzu..."
aws lambda add-permission \
  --function-name "$LAMBDA_NAME" \
  --principal s3.amazonaws.com \
  --statement-id "S3InvokePermission" \
  --action lambda:InvokeFunction \
  --source-arn "arn:aws:s3:::$IN_BUCKET" \
  --no-paginate

# === 4️⃣ S3 Trigger hinzufügen ===
echo "Erstelle S3 Trigger..."
LAMBDA_ARN=$(aws lambda get-function --function-name "$LAMBDA_NAME" --query 'Configuration.FunctionArn' --output text --no-paginate)
aws s3api put-bucket-notification-configuration \
  --bucket "$IN_BUCKET" \
  --notification-configuration "{\"LambdaFunctionConfigurations\":[{\"LambdaFunctionArn\":\"$LAMBDA_ARN\",\"Events\":[\"s3:ObjectCreated:Put\"]}]}" \
  --no-paginate

# === 5️⃣ Test: Bild hochladen und JSON auslesen ===
echo "Lade Test-Bild hoch..."
aws s3 cp "$TEST_IMAGE" s3://$IN_BUCKET/ --region $REGION

echo "Warte 10 Sekunden auf Verarbeitung..."
sleep 10

echo "Hole Ergebnis JSON..."
aws s3 cp s3://$OUT_BUCKET/${TEST_IMAGE}.json "./${TEST_IMAGE}.json" --region $REGION
echo "=== Ergebnis JSON ==="
cat "${TEST_IMAGE}.json"

echo "=== Deployment + Test abgeschlossen ==="
