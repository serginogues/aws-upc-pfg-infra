# S3 backend setup

## Creating the S3 bucket to store the terraform state
In order to use S3 as terraform state backend, we need to 
create the S3 bucket and configure permissions (one-time setup).

We need the S3 backend to access the code tfstate from the 
infra project.

We name it as `aws-upc-pfg-infra-tfstate-bucket-{account-name}`
Where `{account-name}` is the name of the account where the infra project is deployed.
This must be replaced with the actual account name.

```bash
# Create the bucket (replace with your bucket name)
aws s3api create-bucket --bucket aws-upc-pfg-infra-tfstate-bucket-{account-name} --region us-east-1

# Enable versioning (critical for state recovery)
aws s3api put-bucket-versioning --bucket aws-upc-pfg-infra-tfstate-bucket-{account-name} --versioning-configuration Status=Enabled
```
## Configuring the S3 bucket

Now we need to define who can access the bucket and how. 
That is, we need to apply a resource-based policy to the S3 bucket. Before this can be done, the update policy file must be updated
to reflect the account name.

```bash
aws s3api put-bucket-policy --bucket aws-upc-pfg-infra-tfstate-bucket-{account-name} --policy file://tfstate-s3-bucket-policy.json
```
## Configuring the terraform project
Finally, we need to configure the backend in the terraform project. It is not possible to define a backend bucket using a variable
which means the name must be updated manually
