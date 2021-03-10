FROM 905265942603.dkr.ecr.us-east-1.amazonaws.com/openjdk:alpine

EXPOSE 8080
ADD springbootapp.jar springbootapp.jar
ENTRYPOINT ["java", "-jar", "-Xms1024m", "-Xmx1800m", "springbootapp.jar"]
