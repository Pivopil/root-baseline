# App

This project contains an AWS Lambda maven application with [AWS Java SDK 2.x](https://github.com/aws/aws-sdk-java-v2) dependencies.

## Prerequisites
- Java 1.8+
- Apache Maven
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- Docker

## Development

The generated function handler class just returns the input. The configured AWS Java SDK client is created in `DependencyFactory` class and you can 
add the code to interact with the SDK client based on your use case.

#### Building the project
```
mvn clean install
```

#### Testing it locally
```
sam local invoke
```

#### Adding more SDK clients
To add more service clients, you need to add the specific services modules in `pom.xml` and create the clients in `DependencyFactory` following the same 
pattern as s3Client.

## Deployment

The generated project contains a default [SAM template](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html) file `template.yaml` where you can 
configure different properties of your lambda function such as memory size and timeout. You might also need to add specific policies to the lambda function
so that it can access other AWS resources.

To deploy the application, you can run the following command:

```
sam deploy --guided
```

See [Deploying Serverless Applications](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-deploying.html) for more info.


Appendix A

[AWS lambda in Java and terraform](https://medium.com/@pra4mesh/aws-lambda-in-java-and-terraform-544da9102e37)
[AWS lambda SDK](https://aws.amazon.com/blogs/developer/bootstrapping-a-java-lambda-application-with-minimal-aws-java-sdk-startup-time-using-maven/)
[Archetype lambda](https://mvnrepository.com/artifact/software.amazon.awssdk/archetype-lambda)

Create Java 8 Lambda starter from archetype
```shell script
/usr/lib/jvm/jdk1.8.0_221/bin/java -Dmaven.multiModuleProjectDirectory=/tmp/archetypetmp -Dmaven.home=/home/a00627/apps/idea-IU-193.6494.35/plugins/maven/lib/maven3 -Dclassworlds.conf=/home/a00627/apps/idea-IU-193.6494.35/plugins/maven/lib/maven3/bin/m2.conf -Dmaven.ext.class.path=/home/a00627/apps/idea-IU-193.6494.35/plugins/maven/lib/maven-event-listener.jar -javaagent:/home/a00627/apps/idea-IU-193.6494.35/lib/idea_rt.jar=33215:/home/a00627/apps/idea-IU-193.6494.35/bin -Dfile.encoding=UTF-8 -classpath /home/a00627/apps/idea-IU-193.6494.35/plugins/maven/lib/maven3/boot/plexus-classworlds-2.6.0.jar org.codehaus.classworlds.Launcher -Didea.version2019.3.3 -DinteractiveMode=false -DgroupId=org.example -DartifactId=aws-lambda -Dversion=1.0-SNAPSHOT -DarchetypeGroupId=software.amazon.awssdk -DarchetypeArtifactId=archetype-lambda -DarchetypeVersion=2.15.0 -Dregion=us-east-1 -Dservice=s3 org.apache.maven.plugins:maven-archetype-plugin:3.1.0:generate
```

Develop your lambda code
[java-logging-log4j2](https://docs.aws.amazon.com/lambda/latest/dg/java-logging.html#java-logging-log4j2)
[log4j2.xml](https://github.com/awsdocs/aws-lambda-developer-guide/blob/master/sample-apps/blank-java/src/main/resources/log4j2.xml)
[Async Java Handler](https://github.com/awsdocs/aws-lambda-developer-guide/blob/master/sample-apps/blank-java/src/main/java/example/Handler.java)


Build your target
```shell script
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_221
mvn clean install
```

(Optional) Upload it to the S3
```shell script
aws s3 cp ./target/aws-lambda.jar s3://YOUR_PATH --profile YOUR_PROFILE
```




