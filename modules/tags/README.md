============

Tagging

===========

https://d1.awsstatic.com/whitepapers/aws-tagging-best-practices.pdf

1) cosnle org and resource groups (consle UI)


• aws:ec2spot:fleet-request-id identifies the Amazon EC2 Spot Instance Request
that launched the instance
• aws:cloudformation:stack-name identifies the AWS CloudFormation stack that
created the resource
• lambda-console:blueprint identifies blueprint used as a template for an AWS
Lambda function
• elasticbeanstalk:environment-name identifies the application that created the
resource

 "Name" tag for each resource  !!! account-name:resourcename:type

 "dev:my-s3-xaxaxa:aws_s3_bucket"



2) cost (cost center, business unit, or project, user ( financial reporting dimensions within their organization) . The new tag will not apply to past cost allocation reports.

3) automation ( filter resources during infrastructure
automation activities, turn off development environments during non-business
hours to reduce costs. In this scenario) o archive, update, or delete

4) operation (such as backup/restore and operating system patching)
5) acl ( constrain permissions based on specific tags and their values.)

ec2:CreateTags and ec2:DeleteTags


6) security (This can enable automated compliance checks to ensure that proper access
controls are in place, patch compliance is up to date, and so on.)

!!! separate audit account to capture log




1) cosnle org and resource groups
        var.app_env_name                 "app:env" -> "dev"
        var.app_env_version             "app:env:version" -> "0.0.1" // https://semver.org

        // component = org = root public domain
        var.app_env_component_name      "app:component:name" -> "awsdevbot.com" 
        
        // org, env, app

        var.app_env_component_version   "app:component:version" -> "0.0.1"  // https://semver.org
        var.support_email  (contact email) "john.smith@anycompany.com"



awsdevbot:business-contact = Alex Smith;john.smith@anycompany.com;+12015551212
awsdevbot:technical-contact = Susan Jones;sue.jones@anycompany.com;+12015551213

Single Tag Values
anycompany:business-contact-name = John Smith
anycompany:business-contact-email = john.smith@anycompany.com
anycompany:business-contact-phone = +12015551212
anycompany:technical-contact-name = Susan Jones
anycompany:technical-contact-email = sue.jones@anycompany.com
anycompany:technical-contact-phone = +12015551213
        
2) cost 

• anycompany:cost-center to identify the internal Cost Center code
• anycompany:environment-type to identify whether the environment is
development, test, or production
• anycompany:application-id to identify the application the resource was created 

• anycompany:cmdb:application-id – the CMDB Configuration Item ID for the
application that owns the resource
• anycompany:cmdb:cost-center – the Cost Center code associated with the owning
application, sourced from the CMDB
• anycompany:cmdb:application-owner – the individual or group that owns the
application associated with this resource, sourced from the CMDB
        

3) automation
        var.is_temp
        var.expires_at         

4) operation 
        var.deploy_tool      terraform
        var.vcs  app:vcs

        var.app_env_component_backup    app:component:backup 


anycompany:auto-snapshot = { “frequency”: “daily”, “last-backup”:
“2018-04-19T21:18:00.000+0000” }

5) acl   
        account  aws_acc_id
        company  awsdevbot.com
        region   aws_region
        owner    iam_credential name
     

6) security
        compliance       HIPPA, SOX, GDPR
        data_sensitivity Public, Protected, Confidential
        encryption       bool
        public_facing    bool
