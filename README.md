# ec2-computing

These terraform files start up an instance of AWS EC2, which is mainly for Python computing environment.

## Usage

### Initialize

```bash
ssh-keygen -t rsa -f computing_key -N ''
terraform init
```

### Deploy

You can deploy a server by `terraform apply`. You'll need to prepare your AWS profile for deployment in advance. You might want to use aws-vault and add `aws-vault exec <profile> --` as a prefix of the command.

You can set terraform variables via e.g. `terraform.tfvars` or `-var` option (like `terraform apply -var='aws_region=ap-northeast-1'`).

### Use

- The public IP and DNS of the instance will be shown as the output of `terraform apply` command.
- SSH login command will be like `ssh -i computing_key ubuntu@<public IP>`.
- Logs on start-up are stored at `/var/log/cloud-init-output.log` in the instance.
  - Please be aware that currently **the completion of User data scripts isn't monitored by terraform**. You can check this log file to see that.

### Destroy

```bash
terraform destroy
```
