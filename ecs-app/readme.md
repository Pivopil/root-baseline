export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_221


To Run Spring Boot application on the FarGate we need
execute services as tasks of the containers.
For this tasks we  provide task definitions to the AWS ECS. 
For The ECS task definitions we pass a Json file to define application and its properties

[
  {
    "name": "${task_definition_name}",
    "image": "${docker_image_url}",
    // Tell AWS if any of container app fail AWS will replace it with another health docket image instance
    "essential": true,
    // ENV variables for the spring boot app
    "environment": [{
      "name": "spring_profile_active",
      "value": "${spring_profile}"
    }],
    "portMappings": [{
      "containerPort": ${docker_container_port}
    }],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${ecs_service_name}-LogGroup",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${ecs_service_name}-LogGroup-stream"
      }
    }
  }
]
