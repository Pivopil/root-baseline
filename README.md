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

The cutover: Moving your traffic to the cloud
https://www.youtube.com/watch?v=wKD0bT8c0IE

# ELB Refs
aws_lb
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb

ELB SSO integrations 
https://github.com/terraform-aws-modules/terraform-aws-alb/blob/master/examples/complete-alb/main.tf

Security Groups
https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html

Lambda integrations 
https://docs.aws.amazon.com/lambda/latest/dg/services-alb.html

Enable health checks
https://docs.aws.amazon.com/elasticloadbalancing/latest/application/lambda-functions.html#enable-health-checks-lambda

ECS Cluster integration
https://github.com/Pivopil/terraform-aws-ecs-updated/blob/master/2-platform/ecs.tf

Metrics
https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html



https://github.com/terraform-aws-modules/terraform-aws-cloudwatch/tree/master/modules/metric-alarms-by-multiple-dimensions
```shell script
namespace   = "AWS/EC2"
metric_name = "CPUUtilization"
statistic   = "Average"

namespace   = "AWS/EC2"
metric_name = "CPUUtilization"
statistic   = "Maximum"

namespace   = "CustomMachineMetrics"
metric_name = "mem_used_percent"
statistic   = "Average"

namespace   = "CustomMachineMetrics"
metric_name = "mem_used_percent"
statistic   = "Maximum"

namespace   = "CustomMachineMetrics"
metric_name = "disk_used_percent"
statistic   = "Average"

namespace   = "CustomMachineMetrics"
metric_name = "disk_used_percent"
statistic   = "Maximum"
```

https://github.com/terraform-aws-modules/terraform-aws-autoscaling/blob/master/examples/asg_elb/main.tf
    
    


https://github.com/terraform-aws-modules/terraform-aws-cloudwatch/blob/master/examples/multiple-lambda-metric-alarm/main.tf

Troubleshoot your Application Load Balancers
https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html

# Lambda refs
https://github.com/Pivopil/terraform-aws-sls.git
https://github.com/Pivopil/aws-sls-s3-proxy
https://github.com/danilop/serverless-observability-sample-app
https://github.com/terraform-aws-modules/terraform-aws-apigateway-v2

https://docs.aws.amazon.com/whitepapers/latest/serverless-multi-tier-architectures-api-gateway-lambda/serverless-multi-tier-architectures-api-gateway-lambda.pdf
