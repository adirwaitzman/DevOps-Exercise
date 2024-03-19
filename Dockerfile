# Stage 1: build the artifact
FROM maven:3.8.0 AS build
COPY my-app ./my-app
WORKDIR /my-app
RUN mvn package

# Stage 2: Copy only the jar file and run it under non root user
FROM openjdk:11-jre-slim
WORKDIR /app
RUN adduser --system --group adir
RUN chown -R adir:adir /app
USER adir
COPY --from=build --chown=adir:adir /my-app/target/my-app-1.0.*.jar app.jar
CMD ["java", "-jar", "app.jar"]