package com.yep.model;

import java.time.LocalDateTime;

/**
 * Facilitator — a trainer who creates and runs Level One sessions.
 *
 * INHERITANCE: Facilitator IS-A User. It inherits common account
 * fields from User and adds the organisation field specific to
 * facilitators.
 */
public class Facilitator extends User {

    private String organisation;

    // ---- Constructors ----

    public Facilitator(String fullName, String email, String phone,
                       String passwordHash, String country, String organisation) {
        super(fullName, email, phone, passwordHash, country);
        this.organisation = organisation;
    }

    public Facilitator(int userId, String fullName, String email, String phone,
                       String passwordHash, String country,
                       boolean active, boolean consentGiven,
                       int failedLogins, LocalDateTime createdAt,
                       String organisation) {
        super(userId, fullName, email, phone, passwordHash, country,
              active, consentGiven, failedLogins, createdAt);
        this.organisation = organisation;
    }

    // ---- Overriding abstract methods from User (Polymorphism) ----

    @Override
    public String getRole() {
        return "FACILITATOR";
    }

    @Override
    public String getDashboardMenu() {
        return "/facilitator/dashboard.jsp";
    }

    // ---- Getters / Setters ----

    public String getOrganisation()              { return organisation; }
    public void setOrganisation(String org)      { this.organisation = org; }
}
