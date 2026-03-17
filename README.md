# Learning Terraform
To learn the basic syntax I followed along ["Using Terraform" by HashiCorp, an IBM Company](https://www.youtube.com/playlist?list=PL81sUbsFNc5Zs-ZvgC6Yp9D2P7apcc96t).

I then continued with ["Terraform AWS VPC Tutorial - Public, Private, and Isolated Subnets" by Anton Putra](https://www.youtube.com/watch?v=TQ_V9TYoRvw) to learn how to setup VPCs.

To wrap my mind around the resources I need for SSM, I watched ["Connect to EC2 with Session Manager and EC2 Instance Connect" by Digital Cloud Training](https://www.youtube.com/watch?v=3tKB947rT5Q).

All tailored exercises are available in `./aws/exercises`.


## Installation
To manage the resources within the terraform modules, you'll need:
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- Docker (for `./local` module) ([WSL2 setup](https://docs.docker.com/desktop/features/wsl/))
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [AWS CLI SSM Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-linux-overview.html) ([Debian specific instructions](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html))

## Generating SSH Public Key
To log into the public EC2 instance you must have a private-public key pair, and have its path in the terraform variable `public_ssh_key_path` in `./aws/variables.tf`. Create it with:
```
ssh-keygen -t ed25519 -C "learning-terraform-aws-ec2"
```

## Debugging
To debug Terraform, you can view DEBUG logs in `.terraform.log` file within the working dir of any `terraform apply` invocation. Modify logs severity and path in `.vscode/settings.json`.