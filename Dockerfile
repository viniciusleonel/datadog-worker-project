# Etapa 1 — build (se estiver usando Maven)
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .
RUN mvn -B -q -e -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -B -DskipTests package

# Etapa 2 — runtime
FROM eclipse-temurin:21-jdk

WORKDIR /app

# Copia o JAR gerado
COPY --from=build /app/target/*.jar app.jar

# Baixa o Datadog Java Agent
ADD https://dtdg.co/latest-java-tracer /app/dd-java-agent.jar

# Porta da aplicação
EXPOSE 8080

# Executa com o agent
CMD ["java", "-javaagent:/app/dd-java-agent.jar", "-jar", "app.jar"]