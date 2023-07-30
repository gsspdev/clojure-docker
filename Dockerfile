# syntax=docker/dockerfile:1
FROM busybox:latest
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:resolve
COPY src ./src

FROM base as test
RUN ["./mvnw dependency:resolve"]

FROM base as build
RUN ./mvnw package

FROM eclipse-temurin:17-jre-jammy as production
EXPOSE 8080

FROM clojure:temurin-8-tools-deps-bullseye-slim as clojureg
EXPOSE 12240

FROM clojure
COPY . /usr/src/app
WORKDIR /usr/src/app
CMD ["lein", "run"]

FROM clojure
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY project.clj /usr/src/app/
RUN lein deps
COPY . /usr/src/app
RUN mv "$(lein uberjar | sed -n 's/^Created \(.*standalone\.jar\)/\1/p')" app-standalone.jar
CMD ["java", "-jar", "app-standalone.jar"]

# COPY --chmod=755 <<EOF /app/run.sh
# #!/bin/sh
# while true; do
#   echo -ne "The time is now $(date +%T)\\r"
#   sleep 1
# done
ENV buildTag="1.0"

ENTRYPOINT /app/run.sh


# # syntax=docker/dockerfile:1

# FROM eclipse-temurin:17-jdk-jammy as base
# WORKDIR /app
# COPY .mvn/ .mvn
# COPY mvnw pom.xml ./
# RUN ./mvnw dependency:resolve
# COPY src ./src

# FROM base as test
# RUN ["./mvnw", "test"]

# FROM base as development
# CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql", "-Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'"]

# FROM base as build
# RUN ./mvnw package

# FROM eclipse-temurin:17-jre-jammy as production
# EXPOSE 8080
# COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
# CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]