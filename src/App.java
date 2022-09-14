import java.util.Scanner;
import java.util.Properties;
import java.sql.*;

public class App {
    public static void main(String[] args) throws SQLException, ClassNotFoundException {
        Scanner s = new Scanner(System.in);
        String user = "";
        String pass = "";
        boolean loggedIn = false;
        while (!loggedIn) {
            System.out.print("Username: ");
            user = s.next();
            System.out.print("Password: ");
            pass = s.next();
            if (user.equals("admin") && pass.equals("root")) {
                loggedIn = true;
            } else {
                System.out.println("Invalid credentials.");
            }
        }
        System.out.println("Successfully logged in!");
        Class.forName("org.postgresql.Driver");
        String url = "jdbc:postgresql://localhost:5432/";
        Properties props = new Properties();
        props.setProperty("user", "postgres");
        // Replace next line with actual password, but DO NOT PUSH WITH ACTUAL PASSWORD
        props.setProperty("password", "password");
        Connection conn = DriverManager.getConnection(url, props);
        System.out.println("Successfully connected to JDBC");
        boolean done = false;
        while (!done) {
            System.out.println("Program Menu");
            System.out.println("    0 - Exit Program");
            System.out.print("Option: ");
            int option = s.nextInt();
            if (option == 0) {
                done = true;
            }
        }
        System.out.println("Exiting Program...");
        s.close();
    }
}