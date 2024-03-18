# Stage 1: Copy and unzip the artifact
FROM ubuntu:20.04 AS unzip
RUN apt-get update && apt-get install -y unzip
COPY my-app-artifact /app/my-app.zip
WORKDIR /app
RUN unzip my-app.zip -d extracted

# Stage 2: Copy only the jar file and run it under non root user
FROM openjdk:11-jre-slim
WORKDIR /app
RUN adduser --system --group adir
RUN chown -R adir:adir /app
USER adir
COPY --from=unzip --chown=adir:adir /app/extracted/*.jar app.jar
CMD ["java", "-jar", "app.jar"]



