# Exercise 1 — Minimal public/private AWS network

Goal: understand the absolute core objects.

Build:

* one VPC
* two subnets in the same region and AZ
* one internet gateway
* one route table for public access
* one security group

Tasks:

* Make one subnet public and one private.
* Associate only the public subnet with a route table that sends `0.0.0.0/0` to the internet gateway.
* Tag everything consistently.

What to learn:

* what a VPC actually isolates
* the difference between subnet definition and routing
* why “public subnet” is not a subnet type but a routing outcome
* how Terraform resource references wire infra together

Done when:

* you can explain why one subnet is public and the other is not, without handwaving

---

# Notes
- To differentiate between resources I created and default AWS resources you can use the "Default <???>" field for each resource ("Default VPC", "Default subnet" etc.).
- AWS VPC endpoints use the AWS reserved IP ranges, published here in JSON format: https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html. View it using `curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | less`. For example, S3 endpoint in `eu-central-1` uses this CIDR block:
    ```
    ...
        {
        "ip_prefix": "52.219.170.0/23",
        "region": "eu-central-1",
        "service": "S3",
        "network_border_group": "eu-central-1"
        }
    ...
    ```
