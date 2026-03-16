# Learning Terraform
To learn the basic syntax I followed along [this video series](https://www.youtube.com/playlist?list=PL81sUbsFNc5Zs-ZvgC6Yp9D2P7apcc96t).

# Exercises
Yes. Here is a compact exercise ladder that stays practical and aimed at your eventual GeoTrellis deployment.

Start with the mindset that each exercise should end with three things: a Terraform plan that makes sense to you, an apply that succeeds, and a destroy that leaves no leftovers.

## Recommended order

Do 1, 2, 3 first.
Then 4 and 5.
Then 6 and 7.
Then 8, 9, 10.

That path matches your current level much better than jumping straight into “enterprise VPC.”

## A good rule for each exercise

Before you apply, force yourself to answer:

* What is public here?
* What is private here?
* How does outbound internet work?
* What controls inbound traffic?
* What would break if I removed this resource?

That habit is probably more valuable than the Terraform syntax itself.

I can also turn these into a stricter worksheet format with expected deliverables and self-check questions.

# Debugging
To debug Terraform, you can view DEBUG logs in `.terraform.log` file within the working dir of any `terraform apply` invocation. Modify logs severity and path in `.vscode/settings.json`.