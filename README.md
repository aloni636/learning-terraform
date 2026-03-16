# Learning Terraform
To learn the basic syntax I followed along ["Using Terraform" by HashiCorp, an IBM Company](https://www.youtube.com/playlist?list=PL81sUbsFNc5Zs-ZvgC6Yp9D2P7apcc96t). I then continued with ["Terraform AWS VPC Tutorial - Public, Private, and Isolated Subnets" by Anton Putra](https://www.youtube.com/watch?v=TQ_V9TYoRvw) to learn how to setup VPCs. All tailored exercises are available in `./aws/exercises`.

# Debugging
To debug Terraform, you can view DEBUG logs in `.terraform.log` file within the working dir of any `terraform apply` invocation. Modify logs severity and path in `.vscode/settings.json`.