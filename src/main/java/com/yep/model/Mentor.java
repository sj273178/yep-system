package com.yep.model;

import java.time.LocalDateTime;

/**
 * Mentor — guides Level Two teams through their impact projects.
 *
 * INHERITANCE: Mentor IS-A User. Adds expertise and maxTeams fields.
 * The maxTeams field enforces FR14: a mentor may guide at most 3 teams.
 */
public class Mentor extends User {

    private String expertise;
    private int maxTeams;   // default 3 (FR14)

    // ---- Constructors ----

    public Mentor(String fullName, String email, String phone,
                  String passwordHash, String country, String expertise) {
        super(fullName, email, phone, passwordHash, country);
        this.expertise = expertise;
        this.maxTeams  = 3;
    }

    public Mentor(int userId, String fullName, String email, String phone,
                  String passwordHash, String country,
                  boolean active, boolean consentGiven,
                  int failedLogins, LocalDateTime createdAt,
                  String expertise, int maxTeams) {
        super(userId, fullName, email, phone, passwordHash, country,
              active, consentGiven, failedLogins, createdAt);
        this.expertise = expertise;
        this.maxTeams  = maxTeams;
    }

    // ---- Overriding abstract methods from User (Polymorphism) ----

    @Override
    public String getRole() {
        return "MENTOR";
    }

    @Override
    public String getDashboardMenu() {
        return "/mentor/dashboard.jsp";
    }

    // ---- Getters / Setters ----

    public String getExpertise()         { return expertise; }
    public int getMaxTeams()             { return maxTeams; }
    public void setExpertise(String exp) { this.expertise = exp; }
    public void setMaxTeams(int max)     { this.maxTeams = max; }
}
