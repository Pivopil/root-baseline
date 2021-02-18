# root-baseline
root-baseline
# cloudfront ref
https://aws.amazon.com/premiumsupport/knowledge-center/s3-website-cloudfront-error-403/

# RDS IAM Authentication

1) Connect to RDS in EC2
```shell script
mysql -h rds.dev.your-domain.com -P 3306 -u root -p
```

2) Create iam_test_user (you could use any valid name) in mysql 
```sql
CREATE USER iam_test_user IDENTIFIED WITH AWSAuthenticationPlugin as 'RDS';
GRANT USAGE ON *.* TO 'iam_test_user'@'%'REQUIRE SSL;
exit
```

2) in EC2 check you db instance
```shell script
aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,DbiResourceId]" --region us-east-1
[
    [
        "dev-rds",
        "db-dgdfgdfgfgdfg"
    ]
]
```


3) Update IAM instance role with the next inline permission for your rds instance `db-dgdfgdfgfgdfg` and your mysql user `iam_test_user`
```json
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
             "rds-db:connect"
         ],
         "Resource": [
             "arn:aws:rds-db:us-east-1:0000000000:dbuser:db-dgdfgdfgfgdfg/iam_test_user"
         ]
      }
   ]
}
```
4) In EC2
```shell script
RDSHOST=rds.dev.your-domain.com
TOKEN="$(aws rds generate-db-auth-token --hostname rds.dev.your-domain.com --port 3306 --username iam_test --region us-east-1)"
mysql --host=$RDSHOST --port=3306 --ssl-ca=/tmp/rds-combined-ca-bundle.pem --enable-cleartext-plugin --user=iam_test --password=$TOKEN
```

# RDS Refs
https://registry.terraform.io/modules/clowdhaus/rds-proxy/aws/latest
https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest
https://registry.terraform.io/modules/clowdhaus/rds-proxy/aws/latest
