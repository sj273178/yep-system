# ============================================================
# YEP System — container image for online hosting (e.g. Render)
#
# Stage 1 builds the WAR with Maven, stage 2 runs it on Tomcat 10.1.
# The app is deployed as ROOT, so it opens at https://<your-app>/
# Database settings come from the DB_URL, DB_USERNAME and DB_PASSWORD
# environment variables (see DatabaseConnection.java).
# ============================================================

# ---- Stage 1: build ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src ./src
RUN mvn -q clean package -DskipTests

# ---- Stage 2: run ----
FROM tomcat:10.1-jdk21-temurin
RUN rm -rf /usr/local/tomcat/webapps/*

# Turn off Tomcat's shutdown port (8005). Otherwise the hosting service may
# send visitors to 8005 instead of the web port 8080, and every page fails.
RUN sed -i 's/<Server port="8005"/<Server port="-1"/' /usr/local/tomcat/conf/server.xml
COPY --from=build /app/target/yep-system.war /usr/local/tomcat/webapps/ROOT.war

# Free hosting plans have little memory (about 512 MB), so keep Java small
ENV JAVA_OPTS="-Xmx300m -XX:+UseSerialGC"
EXPOSE 8080
CMD ["catalina.sh", "run"]
