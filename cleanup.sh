#!/usr/bin/env bash
set -euo pipefail

REGION="us-west-2"
MGMT_CLUSTER="eksdemo-mgmt-cluster"
STAGING_CLUSTER="eksdemo-staging-cluster"
PROD_CLUSTER="eksdemo-prod-cluster"

echo "====== Step 1: Delete ArgoCD apps (release LBs) ======"
if aws eks describe-cluster --name "$MGMT_CLUSTER" --region "$REGION" &>/dev/null; then
  aws eks update-kubeconfig --region "$REGION" --name "$MGMT_CLUSTER" --quiet || true
  for app in frontend-staging backend-staging frontend-prod backend-prod; do
    kubectl delete application "$app" -n argocd --ignore-not-found --timeout=60s || true
  done
  echo "Waiting 30s for LBs to be released..."
  sleep 30
else
  echo "Mgmt cluster not found, skipping ArgoCD cleanup"
fi

echo ""
echo "====== Step 2: Delete EKS node groups ======"
for CLUSTER in "$STAGING_CLUSTER" "$PROD_CLUSTER" "$MGMT_CLUSTER"; do
  if ! aws eks describe-cluster --name "$CLUSTER" --region "$REGION" &>/dev/null; then
    echo "  $CLUSTER not found, skipping"
    continue
  fi
  NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$CLUSTER" --region "$REGION" --query 'nodegroups[]' --output text 2>/dev/null || true)
  for ng in $NODEGROUPS; do
    echo "  Deleting nodegroup $ng from $CLUSTER..."
    aws eks delete-nodegroup --cluster-name "$CLUSTER" --nodegroup-name "$ng" --region "$REGION" || true
  done
done

echo "Waiting for node groups to delete (~3-5 min)..."
for CLUSTER in "$STAGING_CLUSTER" "$PROD_CLUSTER" "$MGMT_CLUSTER"; do
  aws eks describe-cluster --name "$CLUSTER" --region "$REGION" &>/dev/null || continue
  NODEGROUPS=$(aws eks list-nodegroups --cluster-name "$CLUSTER" --region "$REGION" --query 'nodegroups[]' --output text 2>/dev/null || true)
  for ng in $NODEGROUPS; do
    echo "  Waiting for $ng in $CLUSTER..."
    aws eks wait nodegroup-deleted --cluster-name "$CLUSTER" --nodegroup-name "$ng" --region "$REGION" || true
  done
done

echo ""
echo "====== Step 3: Delete EKS clusters ======"
for CLUSTER in "$STAGING_CLUSTER" "$PROD_CLUSTER" "$MGMT_CLUSTER"; do
  if aws eks describe-cluster --name "$CLUSTER" --region "$REGION" &>/dev/null; then
    echo "  Deleting $CLUSTER..."
    aws eks delete-cluster --name "$CLUSTER" --region "$REGION" || true
  else
    echo "  $CLUSTER not found, skipping"
  fi
done

echo "Waiting for clusters to delete (~3-5 min)..."
for CLUSTER in "$STAGING_CLUSTER" "$PROD_CLUSTER" "$MGMT_CLUSTER"; do
  aws eks describe-cluster --name "$CLUSTER" --region "$REGION" &>/dev/null || continue
  aws eks wait cluster-deleted --name "$CLUSTER" --region "$REGION" || true
done

echo ""
echo "====== Step 4: Delete RDS instances ======"
for DB in mydb eksdemo-staging-mydb staging-mydb prod-mydb; do
  if aws rds describe-db-instances --db-instance-identifier "$DB" --region "$REGION" &>/dev/null 2>&1; then
    echo "  Deleting RDS instance $DB..."
    aws rds delete-db-instance --db-instance-identifier "$DB" --skip-final-snapshot --region "$REGION" || true
  fi
done

echo "Waiting for RDS instances to delete (~5-10 min)..."
for DB in mydb eksdemo-staging-mydb staging-mydb prod-mydb; do
  aws rds describe-db-instances --db-instance-identifier "$DB" --region "$REGION" &>/dev/null 2>&1 || continue
  aws rds wait db-instance-deleted --db-instance-identifier "$DB" --region "$REGION" || true
done

echo ""
echo "====== Step 5: Delete RDS subnet groups ======"
for SG_NAME in rds-subnet-group staging-rds-subnet-group prod-rds-subnet-group dev-rds-subnet-group; do
  aws rds delete-db-subnet-group --db-subnet-group-name "$SG_NAME" --region "$REGION" 2>/dev/null && echo "  Deleted $SG_NAME" || true
done

echo ""
echo "====== Step 6: Delete Secrets Manager secrets ======"
for SECRET in rds-credentials rds-creds-staging rds-creds-prod rds-creds-dev; do
  ARN=$(aws secretsmanager list-secrets --region "$REGION" --query "SecretList[?starts_with(Name,'$SECRET')].ARN" --output text 2>/dev/null || true)
  for arn in $ARN; do
    echo "  Deleting secret $arn..."
    aws secretsmanager delete-secret --secret-id "$arn" --force-delete-without-recovery --region "$REGION" || true
  done
done

echo ""
echo "====== Step 7: Delete ECR repositories ======"
for REPO in frontend-dev backend-dev frontend-staging backend-staging frontend-prod backend-prod; do
  if aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" &>/dev/null 2>&1; then
    echo "  Deleting ECR repo $REPO..."
    aws ecr delete-repository --repository-name "$REPO" --force --region "$REGION" || true
  fi
done

echo ""
echo "====== Step 8: Delete Load Balancers (orphaned from K8s) ======"
LB_ARNS=$(aws elbv2 describe-load-balancers --region "$REGION" \
  --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null || true)
for arn in $LB_ARNS; do
  echo "  Deleting LB $arn..."
  aws elbv2 delete-load-balancer --load-balancer-arn "$arn" --region "$REGION" || true
done
[ -n "$LB_ARNS" ] && sleep 15 || true

echo ""
echo "====== Step 9: Delete VPCs ======"
VPC_IDS=$(aws ec2 describe-vpcs --region "$REGION" \
  --filters "Name=isDefault,Values=false" \
  --query 'Vpcs[].VpcId' --output text 2>/dev/null || true)

for VPC_ID in $VPC_IDS; do
  echo "  Cleaning VPC $VPC_ID..."

  # Delete target groups
  TG_ARNS=$(aws elbv2 describe-target-groups --region "$REGION" \
    --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text 2>/dev/null || true)
  for arn in $TG_ARNS; do aws elbv2 delete-target-group --target-group-arn "$arn" --region "$REGION" 2>/dev/null || true; done

  # Delete subnets
  SUBNETS=$(aws ec2 describe-subnets --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[].SubnetId' --output text 2>/dev/null || true)
  for subnet in $SUBNETS; do aws ec2 delete-subnet --subnet-id "$subnet" --region "$REGION" 2>/dev/null || true; done

  # Detach and delete internet gateways
  IGW_IDS=$(aws ec2 describe-internet-gateways --region "$REGION" \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[].InternetGatewayId' --output text 2>/dev/null || true)
  for igw in $IGW_IDS; do
    aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$VPC_ID" --region "$REGION" 2>/dev/null || true
    aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$REGION" 2>/dev/null || true
  done

  # Delete non-main route tables
  RTS=$(aws ec2 describe-route-tables --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[?Associations[?Main==`false`] || length(Associations)==`0`].RouteTableId' \
    --output text 2>/dev/null || true)
  for rt in $RTS; do aws ec2 delete-route-table --route-table-id "$rt" --region "$REGION" 2>/dev/null || true; done

  # Delete non-default security groups
  SGS=$(aws ec2 describe-security-groups --region "$REGION" \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null || true)
  for sg in $SGS; do aws ec2 delete-security-group --group-id "$sg" --region "$REGION" 2>/dev/null || true; done

  # Delete VPC
  aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION" 2>/dev/null && echo "  Deleted VPC $VPC_ID" || echo "  Could not delete VPC $VPC_ID (may have remaining dependencies)"
done

echo ""
echo "====== Done! ======"
echo "Note: Terraform state buckets and DynamoDB lock tables were NOT deleted."
echo "Run the following to remove them if needed:"
echo "  aws s3 rb s3://eksdemo-terraform-state --force --region $REGION"
echo "  aws dynamodb delete-table --table-name terraform-locks --region $REGION"
