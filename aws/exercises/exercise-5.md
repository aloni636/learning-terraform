# Exercise 5 — Private S3 access through a gateway endpoint

Starting point:

* private EC2 instances are already manageable through SSM
* networking works across public and private subnets

Goal: give private instances controlled access to S3 without routing that traffic through NAT.

Build:

* one S3 bucket for application data, artifacts, or logs
* one S3 gateway endpoint attached to the private route tables
* one IAM policy granting private EC2 only the bucket access it needs
* one validation flow from a private instance

Tasks:

* Create a bucket with a stable, project-specific naming scheme.
* Add a VPC endpoint for S3 and associate it with the private route tables.
* Attach only the minimum bucket permissions your private EC2 instances need.
* From a private instance, upload and fetch a test object.
* Explain the difference between network access to S3 and IAM permission to use S3.
* Explain what changes in the route tables and what does not.

What to learn:

* gateway endpoints for S3
* IAM scoping for bucket access
* the difference between network path and authorization

Done when:

* a private instance can use exactly one S3 bucket through the S3 endpoint and without relying on NAT

