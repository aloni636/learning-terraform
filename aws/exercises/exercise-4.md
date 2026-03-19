# Exercise 4 — Split by availability zones

Goal: stop building single-point-of-failure toy networks.

Build:

* one VPC
* two public subnets in different AZs
* two private subnets in different AZs
* routing that matches the design

Tasks:

* Name the subnets clearly by role and AZ.
* Decide whether you want one NAT gateway or one per AZ.
* Write down the tradeoff: cheaper vs more resilient.

What to learn:

* availability zones
* why subnet layout matters later for managed services
* cost/resilience tradeoffs in network design

Done when:

* your naming and topology are readable without opening the AWS console diagram

---

NAT for each AZ is more resilient but costs ~32$ per AZ plus 0.05$ per GB data processing cost, which is actually 2.5x higher then cross AZ data transfers (accounting for per direction cost)
See: [NAT Pricing](https://aws.amazon.com/vpc/pricing/#:~:text=VPC%20Encryption%20Controls-,NAT%20Gateway%20Pricing,-If%20you%20choose), [Cross Region Pricing](https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer_within_the_same_AWS_Region:~:text=Data%20Transfer%20within%20the%20same%20AWS%20Region)