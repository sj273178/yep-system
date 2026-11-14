package com.yep.util;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * DatabaseConnection — provides a JDBC connection to the MySQL database.
 *
 * HOW JDBC WORKS:
 *   1. The JDBC driver (mysql-connector-j) translates Java method calls
 *      into the MySQL wire protocol.
 *   2. DriverManager.getConnection() opens a TCP socket to the database
 *      server and returns a Connection object.
 *   3. We use that Connection to create PreparedStatement objects,
 *      execute SQL queries, and read ResultSet rows.
 *
 * The database URL, username and password are read from
 * src/main/resources/database.properties so they are never hard-coded
 * in the source code (a security best practice).
 *
 * IMPORTANT: Always call connection.close() when you are done, or use
 * a try-with-resources block so Java closes it automatically.
 */
public class DatabaseConnection {

    private static String url;
    private static String username;
    private static String password;

    // Static initialiser — runs once when the class is first loaded.
    // Reads credentials from the properties file.
    static {
        try (InputStream input = DatabaseConnection.class
                .getClassLoader()
                .getResourceAsStream("database.properties")) {

            Properties props = new Properties();
            props.load(input);

            // Load the MySQL JDBC driver class explicitly. Inside Tomcat the
            // automatic driver discovery does not see jars in WEB-INF/lib,
            // which causes "No suitable driver found" without this line.
            Class.forName("com.mysql.cj.jdbc.Driver");

            // On a hosting service (e.g. Render) the settings come from environment
            // variables, so the online database password is never stored in the code.
            // On your own computer these are not set, so database.properties is used.
            url      = setting("DB_URL",      props.getProperty("db.url"));
            username = setting("DB_USERNAME", props.getProperty("db.username"));
            password = setting("DB_PASSWORD", props.getProperty("db.password"));

        } catch (Exception e) {
            throw new RuntimeException("Could not load database settings or the MySQL driver: " + e.getMessage(), e);
        }
    }

    /** Returns the environment variable if it is set, otherwise the default value. */
    private static String setting(String envName, String defaultValue) {
        String value = System.getenv(envName);
        return (value == null || value.isBlank()) ? defaultValue : value;
    }

    /**
     * Opens and returns a new database connection.
     * The caller is responsible for closing it (preferably with try-with-resources).
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, username, password);
    }
}
