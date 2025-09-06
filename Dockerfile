# 1) Build do JAR
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY . .
RUN mvn -DskipTests package

# 2) Training (gera o .jsa)
FROM eclipse-temurin:21-jdk AS train
WORKDIR /opt/app
COPY --from=build /workspace/target/app-cds-api.jar app.jar
RUN java -XX:ArchiveClassesAtExit=/opt/app/application.jsa \
         -Dspring.context.exit=onRefresh \
         -jar app.jar

# 3) Runtime (usa o .jsa)
FROM eclipse-temurin:21-jre
WORKDIR /opt/app
COPY --from=build /workspace/target/app-cds-api.jar app.jar
COPY --from=train /opt/app/application.jsa application.jsa
ENV JAVA_TOOL_OPTIONS="-Xshare:on -XX:SharedArchiveFile=/opt/app/application.jsa"
ENTRYPOINT ["java","-jar","/opt/app/app.jar"]
