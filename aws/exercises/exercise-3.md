# Exercise 3 — Private subnet internet access through NAT

Goal: understand the classic “private compute, outbound internet only” pattern.

Build:

* NAT gateway in the public subnet
* elastic IP for the NAT gateway
* separate route table for the private subnet

Tasks:

* Route private subnet default traffic to the NAT gateway.
* Keep inbound access from the internet blocked to the private subnet.
* Explain why the NAT gateway must sit in a public subnet.

What to learn:

* outbound-only internet access
* why private workloads still often need internet access
* the cost implication of NAT gateways

Done when:

* you can explain why package installs from a private machine may work while SSH from the internet still does not

---

Once `terraform apply` completes, we can connect to the private instance via SSM (see `private_instance_id` output), and poke around to verify the network topology works as intended:
```
$ ping google.com
... This machine has access to the internet ...
$ hostname
$ ip addr
$ ip route
... IP range of this machine is within the private subnet ...

$ curl -s ifconfig.me
... IP of the NAT gateway (view it in the AWS console: VPC > NAT gateways > Primary public IPv4 address) ...

$ getent hosts ssm.eu-central-1.amazonaws.com
... IP within the private subnet range ...
$ getent hosts ssmmessages.eu-central-1.amazonaws.com
... IP within the private subnet range ...
$ getent hosts ec2messages.eu-central-1.amazonaws.com
... IP within the private subnet range ...
```
