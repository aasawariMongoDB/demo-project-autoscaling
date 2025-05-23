FROM amazoncorretto:21
WORKDIR /present
COPY target/autoscaling-springboot-eks-0.0.1-SNAPSHOT.jar application.jar
ENTRYPOINT ["java", "-jar", "application.jar"]
