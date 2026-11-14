package com.yep.model;

import java.time.LocalDateTime;

/**
 * Admin — the YEP Secretariat staff who manage the platform.
 *
 * INHERITANCE: Admin IS-A User. No extra fields are needed beyond
 * what User already provides; the class exists to give admins their
 * own role, dashboard, and permission scope.
 */
public class Admin extends User {

    // ---- Constructors ----

    public Admin(String fullName, String email, String phone,
                 String passwordHash, String country) {
        super(fullName, email, phone, passwordHash, country);
    }

    public Admin(int userId, String fullName, String email, String phone,
                 String passwordHash, String country,
                 boolean active, boolean consentGiven,
                 int failedLogins, LocalDateTime createdAt) {
        super(userId, fullName, email, phone, passwordHash, country,
              active, consentGiven, failedLogins, createdAt);
    }

    // ---- Overriding abstract methods from User (Polymorphism) ----

    @Override
    public String getRole() {
        return "ADMIN";
    }

    @Override
    public String getDashboardMenu() {
        return "/admin";   // AdminServlet loads the dashboard figures
    }
}
