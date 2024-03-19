FROM openjdk:11-jre-slim
WORKDIR /app
RUN adduser --system --group adir
RUN chown -R adir:adir /app
USER adir
COPY --chown=adir:adir my-app-artifact.jar app.jar
CMD ["java", "-jar", "app.jar"]