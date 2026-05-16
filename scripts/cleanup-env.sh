#!/bin/bash
# Deletes all resources created by the eksdemo environment.
# Usage: ./cleanup-env.sh [name_prefix] [region]
# Example: ./cleanup-env.sh eksdemo us-west-2

NAME_PREFIX="${1:-eksdemo}"
REGION="${2:-us-west-2}"
CLUSTER_NAME="${NAME_PREFIX}-cluster"

echo "==> Cleaning up environment: $NAME_PREFIX (region: $REGION)"
echo "    Cluster: $CLUSTER_NAME"
echo ""

# ── EKS Node Groups ──────────────────────────────────────────────────────────
echo "[1/11] Deleting EKS node groups..."
NODE_GROUPS=$(aws eks list-nodegroups \
  --cluster-name "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'nodegroups[*]' --output text 2>/dev/null)

for ng in $NODE_GROUPS; do
  echo "  Deleting node group: $ng"
  aws eks delete-nodegroup \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$ng" \
    --region "$REGION" || true
done

# Wait for node groups to finish deleting
for ng in $NODE_GROUPS; do
  echo "  Waiting for node group $ng to be deleted..."
  aws eks wait nodegroup-deleted \
    --cluster-name "$CLUSTER_NAME" \
    --nodegroup-name "$ng" \
    --region "$REGION" 2>/dev/null || true
done

# ── EKS Cluster ──────────────────────────────────────────────────────────────
echo "[2/11] Deleting EKS cluster..."
aws eks delete-cluster --name "$CLUSTER_NAME" --region "$REGION" 2>/dev/null || true
aws eks wait cluster-deleted --name "$CLUSTER_NAME" --region "$REGION" 2>/dev/null || true

# ── RDS Instance ─────────────────────────────────────────────────────────────
echo "[3/11] Deleting RDS instance..."
aws rds delete-db-instance \
  --db-instance-identifier "mydb" \
  --skip-final-snapshot \
  --region "$REGION" 2>/dev/null || true
echo "  Waiting for RDS to be deleted (this can take a few minutes)..."
aws rds wait db-instance-deleted \
  --db-instance-identifier "mydb" \
  --region "$REGION" 2>/dev/null || true

# ── RDS Subnet Group ─────────────────────────────────────────────────────────
echo "[4/11] Deleting RDS subnet group..."
aws rds delete-db-subnet-group \
  --db-subnet-group-name "rds-subnet-group" \
  --region "$REGION" 2>/dev/null || true

# ── Secrets Manager ──────────────────────────────────────────────────────────
echo "[5/11] Deleting Secrets Manager secrets..."
SECRETS=$(aws secretsmanager list-secrets \
  --region "$REGION" \
  --query "SecretList[?starts_with(Name, 'rds-creds')].Name" --output text)

for secret in $SECRETS; do
  echo "  Deleting secret: $secret"
  aws secretsmanager delete-secret \
    --secret-id "$secret" \
    --force-delete-without-recovery \
    --region "$REGION" 2>/dev/null || true
done

# ── ECR Repositories ─────────────────────────────────────────────────────────
echo "[6/11] Deleting ECR repositories..."
for repo in frontend backend; do
  echo "  Deleting ECR repo: $repo"
  aws ecr delete-repository \
    --repository-name "$repo" \
    --force \
    --region "$REGION" 2>/dev/null || true
done

# ── Load Balancers (created by Kubernetes) ───────────────────────────────────
echo "[7/11] Deleting load balancers..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=${NAME_PREFIX}-vpc" \
  --query 'Vpcs[0].VpcId' --output text --region "$REGION" 2>/dev/null)

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  LB_ARNS=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
    --output text --region "$REGION" 2>/dev/null)
  for arn in $LB_ARNS; do
    echo "  Deleting LB: $arn"
    aws elbv2 delete-load-balancer --load-balancer-arn "$arn" --region "$REGION" || true
  done
  [ -n "$LB_ARNS" ] && sleep 15

  TG_ARNS=$(aws elbv2 describe-target-groups \
    --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" \
    --output text --region "$REGION" 2>/dev/null)
  for arn in $TG_ARNS; do
    aws elbv2 delete-target-group --target-group-arn "$arn" --region "$REGION" || true
  done

# ── Security Groups ───────────────────────────────────────────────────────────
  echo "[8/11] Deleting security groups..."
  SGS=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[?GroupName!='default'].GroupId" \
    --output text --region "$REGION" 2>/dev/null)
  for sg in $SGS; do
    aws ec2 delete-security-group --group-id "$sg" --region "$REGION" 2>/dev/null || true
  done

# ── ENIs ─────────────────────────────────────────────────────────────────────
  ENIS=$(aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "NetworkInterfaces[?Status=='available'].NetworkInterfaceId" \
    --output text --region "$REGION" 2>/dev/null)
  for eni in $ENIS; do
    aws ec2 delete-network-interface --network-interface-id "$eni" --region "$REGION" 2>/dev/null || true
  done

# ── VPC Resources ─────────────────────────────────────────────────────────────
  echo "[9/11] Deleting VPC and networking..."
  IGW=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[0].InternetGatewayId' --output text --region "$REGION" 2>/dev/null)
  if [ -n "$IGW" ] && [ "$IGW" != "None" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID" --region "$REGION" || true
    aws ec2 delete-internet-gateway --internet-gateway-id "$IGW" --region "$REGION" || true
  fi

  NATS=$(aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query 'NatGateways[*].NatGatewayId' --output text --region "$REGION" 2>/dev/null)
  for nat in $NATS; do
    aws ec2 delete-nat-gateway --nat-gateway-id "$nat" --region "$REGION" || true
  done
  [ -n "$NATS" ] && sleep 20

  SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].SubnetId' --output text --region "$REGION" 2>/dev/null)
  for subnet in $SUBNETS; do
    aws ec2 delete-subnet --subnet-id "$subnet" --region "$REGION" 2>/dev/null || true
  done

  RTS=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
    --output text --region "$REGION" 2>/dev/null)
  for rt in $RTS; do
    aws ec2 delete-route-table --route-table-id "$rt" --region "$REGION" 2>/dev/null || true
  done

  aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION" 2>/dev/null || true
  echo "  VPC $VPC_ID deleted"
else
  echo "  VPC not found — skipping networking cleanup"
fi

# ── IAM Roles ────────────────────────────────────────────────────────────────
echo "[10/11] Deleting IAM roles..."
IAM_ROLES=$(aws iam list-roles \
  --query "Roles[?starts_with(RoleName, '${CLUSTER_NAME}')].RoleName" \
  --output text 2>/dev/null)

for role in $IAM_ROLES; do
  echo "  Deleting role: $role"
  # Detach all managed policies first
  POLICIES=$(aws iam list-attached-role-policies \
    --role-name "$role" \
    --query 'AttachedPolicies[*].PolicyArn' --output text 2>/dev/null)
  for policy in $POLICIES; do
    aws iam detach-role-policy --role-name "$role" --policy-arn "$policy" 2>/dev/null || true
  done
  # Delete inline policies
  INLINE=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames[*]' --output text 2>/dev/null)
  for pol in $INLINE; do
    aws iam delete-role-policy --role-name "$role" --policy-name "$pol" 2>/dev/null || true
  done
  aws iam delete-role --role-name "$role" 2>/dev/null || true
done

# ── OIDC Provider ─────────────────────────────────────────────────────────────
OIDC_ARNS=$(aws iam list-open-id-connect-providers \
  --query 'OpenIDConnectProviderList[*].Arn' --output text 2>/dev/null)
for arn in $OIDC_ARNS; do
  aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "$arn" 2>/dev/null || true
done

# ── Terraform State ───────────────────────────────────────────────────────────
echo "[11/11] Deleting Terraform state..."
aws s3 rm s3://eksdemo-terraform-state --recursive --region "$REGION" 2>/dev/null || true
aws s3api delete-bucket --bucket eksdemo-terraform-state --region "$REGION" 2>/dev/null || true
aws dynamodb delete-table --table-name terraform-locks --region "$REGION" 2>/dev/null || true

echo ""
echo "==> Cleanup complete for: $NAME_PREFIX"
