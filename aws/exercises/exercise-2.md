# Exercise 2 — Add EC2 and prove connectivity assumptions

Goal: stop thinking of networking as abstract boxes.

Build:

* one EC2 instance in the public subnet
* optionally one EC2 instance in the private subnet

Tasks:

* Give the public instance a public IP.
* Allow SSH only from your own IP in the security group.
* For the private instance, do not give it a public IP.
* Reason in writing: which instance can be reached from your laptop, and why?

What to learn:

* security groups vs route tables
* public IP vs private IP
* why “being in the VPC” does not mean “reachable”

Done when:

* you can predict reachability before testing

