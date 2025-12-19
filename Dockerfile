FROM openjdk:17
COPY target/*.jar /app/boot.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/boot.jar"]