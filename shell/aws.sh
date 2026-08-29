# AWS helper utilities. Bash 3.2 compatible; aws-cli is the only hard dependency.

_aws_need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'aws-utils: required command not found: %s\n' "$1" >&2
    return 127
  }
}

_aws_region() {
  aws configure get region 2>/dev/null || echo "us-east-1"
}

eks_ami() {
  _aws_need aws || return

  if [ "$1" = "--list" ]; then
    eks_ami_versions "${AWS_REGION:-$(_aws_region)}"
    return
  fi

  [ "$#" -ge 1 ] && [ "$#" -le 2 ] || { printf 'usage: eks_ami KUBE_VERSION [AMI_TYPE]\n' >&2; return 2; }
  local version="$1" ami_type="${2:-amazon-linux-2023/x86_64/standard}" region="${AWS_REGION:-$(_aws_region)}" ami

  # Correct path: /aws/service/eks/optimized-ami/{version}/{ami-type}/recommended/image_id
  ami="$(aws ssm get-parameter --name "/aws/service/eks/optimized-ami/${version}/${ami_type}/recommended/image_id" \
    --region "$region" --query "Parameter.Value" --output text 2>/dev/null)"
  if [ -n "$ami" ] && [ "$ami" != "None" ]; then
    printf '%s\n' "$ami"
    return 0
  fi

  printf 'eks_ami: no AMI found for EKS %s with type %s in %s\n' "$version" "$ami_type" "$region" >&2
  printf 'Available AMI types: amazon-linux-2023/x86_64/standard, amazon-linux-2023/arm64/standard, etc.\n' >&2
  return 1
}

eks_ami_versions() {
  _aws_need aws || return
  local region="${1:-$(_aws_region)}"

  printf 'EKS AMI parameter path format:\n\n' >&2
  printf '  /aws/service/eks/optimized-ami/<VERSION>/<AMI_TYPE>/recommended/image_id\n\n' >&2
  printf 'Available AMI types:\n' >&2
  printf '  - amazon-linux-2023/x86_64/standard (default, recommended)\n' >&2
  printf '  - amazon-linux-2023/x86_64/nvidia\n' >&2
  printf '  - amazon-linux-2023/arm64/standard (AWS Graviton)\n' >&2
  printf '  - amazon-linux-2023/arm64/nvidia\n' >&2
  printf '  - amazon-linux-2023/x86_64/neuron (AWS Neuron)\n\n' >&2
  printf 'Reference: https://docs.aws.amazon.com/eks/latest/userguide/retrieve-ami-id.html\n' >&2
}

aws_whoami() {
  _aws_need aws || return
  printf 'AWS Identity:\n'
  aws sts get-caller-identity --output table
}

aws_region() {
  local region
  if [ "$#" -eq 0 ]; then
    region="$(_aws_region)"
    [ -n "$region" ] && printf '%s\n' "$region" || printf 'us-east-1 (default)\n'
  else
    export AWS_REGION="$1"
    printf 'AWS_REGION set to %s\n' "$1"
  fi
}

s3_bucket_size() {
  _aws_need aws || return
  [ "$#" -eq 1 ] || { printf 'usage: s3_bucket_size BUCKET\n' >&2; return 2; }
  local bucket="$1"

  printf 'Calculating size of s3://%s (this may take a moment)...\n' "$bucket" >&2
  aws s3 ls "s3://$bucket" --recursive --summarize --human-readable | grep "Total Size:"
}

ec2_instances() {
  _aws_need aws || return
  local filter='' query
  [ "$#" -eq 0 ] || filter="--filters Name=tag:$1,Values=${2:-*}"

  query='Reservations[].Instances[].[InstanceId,State.Name,InstanceType,LaunchTime,Tags[?Key==`Name`].Value|[0]]'
  aws ec2 describe-instances $filter --query "$query" --output table
}

ec2_stop() {
  [ "$#" -eq 1 ] || { printf 'usage: ec2_stop INSTANCE_ID\n' >&2; return 2; }
  printf 'Stopping instance %s...\n' "$1" >&2
  aws ec2 stop-instances --instance-ids "$1" --output table
}

ec2_start() {
  [ "$#" -eq 1 ] || { printf 'usage: ec2_start INSTANCE_ID\n' >&2; return 2; }
  printf 'Starting instance %s...\n' "$1" >&2
  aws ec2 start-instances --instance-ids "$1" --output table
}

iam_policies() {
  _aws_need aws || return
  [ "$#" -eq 1 ] || { printf 'usage: iam_policies ROLE_NAME\n' >&2; return 2; }
  local role="$1"

  printf 'Inline policies for role %s:\n' "$role" >&2
  aws iam list-role-policies --role-name "$role" --output table

  printf '\nAttached policies for role %s:\n' "$role" >&2
  aws iam list-attached-role-policies --role-name "$role" --output table
}

iam_show_policy() {
  _aws_need aws || return
  [ "$#" -eq 2 ] || { printf 'usage: iam_show_policy ROLE_NAME POLICY_NAME\n' >&2; return 2; }

  aws iam get-role-policy --role-name "$1" --policy-name "$2" --query 'RolePolicyDocument' --output json | jq .
}

secretsmanager_get() {
  _aws_need aws || return
  [ "$#" -eq 1 ] || { printf 'usage: secretsmanager_get SECRET_NAME\n' >&2; return 2; }

  aws secretsmanager get-secret-value --secret-id "$1" --query 'SecretString' --output text
}

secretsmanager_list() {
  _aws_need aws || return
  aws secretsmanager list-secrets --query 'SecretList[].[Name,LastChangedDate]' --output table
}

kms_decrypt() {
  _aws_need aws || return
  [ "$#" -eq 1 ] || { printf 'usage: kms_decrypt FILE\n' >&2; return 2; }

  aws kms decrypt --ciphertext-blob fileb://"$1" --query Plaintext --output text | base64 --decode
}

rds_snapshots() {
  _aws_need aws || return
  local db_id="${1:-}"
  local query='DBSnapshots[].[DBSnapshotIdentifier,Engine,SnapshotCreateTime,Status]'

  if [ -n "$db_id" ]; then
    aws rds describe-db-snapshots --db-instance-identifier "$db_id" --query "$query" --output table
  else
    aws rds describe-db-snapshots --query "$query" --output table
  fi
}

lambda_logs() {
  _aws_need aws || return
  [ "$#" -eq 1 ] || { printf 'usage: lambda_logs FUNCTION_NAME\n' >&2; return 2; }

  printf 'Recent Lambda logs for %s:\n' "$1" >&2
  aws logs tail "/aws/lambda/$1" --follow --format short
}

cloudformation_stack_status() {
  _aws_need aws || return
  [ "$#" -eq 1 ] || { printf 'usage: cloudformation_stack_status STACK_NAME\n' >&2; return 2; }

  aws cloudformation describe-stacks --stack-name "$1" \
    --query 'Stacks[0].[StackName,StackStatus,CreationTime]' --output table
}

_aws_help() {
  cat <<'EOF'
AWS CLI helper utilities

Identity and configuration
  aws_whoami                show current AWS account/user/role
  aws_region [REGION]       show or set AWS region

EKS utilities
  eks_ami VERSION [TYPE]    get recommended AMI ID for EKS version
                            TYPE: amazon-linux-2023/x86_64/standard (default)
                                  amazon-linux-2023/arm64/standard, etc.
  eks_ami --list            show path formats and AWS docs link

EC2 utilities
  ec2_instances [TAG VAL]   list running instances (optionally filter by tag)
  ec2_start INSTANCE_ID     start an EC2 instance
  ec2_stop INSTANCE_ID      stop an EC2 instance

IAM utilities
  iam_policies ROLE_NAME    list inline and attached policies for role
  iam_show_policy ROLE POLICY
                            show details of an inline IAM policy

Secrets and encryption
  secretsmanager_get NAME   fetch secret from Secrets Manager
  secretsmanager_list       list all secrets with last modified date
  kms_decrypt FILE          decrypt a KMS-encrypted file

RDS utilities
  rds_snapshots [DB_ID]     list DB snapshots (optionally filter by DB)

Lambda and CloudFormation
  lambda_logs FUNCTION      tail logs for a Lambda function
  cloudformation_stack_status STACK
                            show stack status

Examples:
  eks_ami 1.32
  ec2_instances Environment production
  lambda_logs my-function
  secretsmanager_get database-credentials
EOF
}
