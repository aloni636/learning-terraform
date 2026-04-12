# Exercise 6 — Create a private RDS tier

Starting point:

* public and private EC2 already exist
* the VPC currently has public and private subnet tiers

Goal: add a database tier and create one private RDS instance with a clear connection path from the private application tier.

Build:

* two database subnets in different AZs
* one DB subnet group
* one database security group
* one PostgreSQL or MySQL RDS instance
* one security group rule allowing only private application instances to reach the database port

Tasks:

* Extend the subnet model to include a database tier.
* Create a DB subnet group from the database subnets.
* Choose one engine only: PostgreSQL or MySQL.
* Start with a small single-instance database.
* Keep `publicly_accessible = false`.
* Model traffic as a sentence first:
  "private app instances may talk to the database on port X."
* Encode that sentence with security-group-to-security-group references where possible.
* Connect from a private EC2 instance and verify that the path works.
* Write down which parts of this design are learning-safe defaults and which parts you would change later.

What to learn:

* database subnet placement
* DB subnet groups
* security group design for application-to-database traffic
* the minimum moving parts for a first RDS deployment

Done when:

* a private instance can connect to one non-public RDS instance and the network path is clear

