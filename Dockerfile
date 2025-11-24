FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM azul/zulu-openjdk:21-jre
WORKDIR /app
COPY --from=build /app/target/spring-boot-demo-0.0.1-SNAPSHOT.jar app.jar
RUN mkdir -p /tmp/logs /tmp/data
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]