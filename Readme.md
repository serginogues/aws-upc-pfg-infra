# S3 backend setup

In order to use S3 as terraform state backend, we need to 
create the S3 bucket and configure permissions (one-time setup).

We need the S3 backend to access the code tfstate from the 
infra project.

We name it as `aws-upc-pfg-tfstate-bucket`:
```bash
# Create the bucket (replace with your bucket name)
aws s3api create-bucket --bucket aws-upc-pfg-infra-tfstate-bucket --region us-east-1

# Enable versioning (critical for state recovery)
aws s3api put-bucket-versioning --bucket aws-upc-pfg-infra-tfstate-bucket --versioning-configuration Status=Enabled
```

Now we need to define who can access the bucket and how. 
That is, we need to apply a resource-based policy to the S3 bucket:
```bash
aws s3api put-bucket-policy --bucket aws-upc-pfg-infra-tfstate-bucket --policy file://tfstate-s3-bucket-policy.json
```
