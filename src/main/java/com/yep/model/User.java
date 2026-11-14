package com.yep.model;

import java.time.LocalDateTime;

/**
 * User — abstract superclass for all accounts in the YEP system.
 *
 * ABSTRACTION: This class is abstract because a bare "User" never
 * exists on its own — every real account is a Participant, Facilitator,
 * Mentor, or Admin. Making it abstract forces subclasses to provide
 * getRole() and getDashboardMenu().
 *
 * ENCAPSULATION: All fields are private. Getters allow reading;
 * setters include basic validation where needed. The passwordHash
 * field has NO getter — once stored it should never be read back
 * into plain text.
 *
 * INHERITANCE: Participant, Facilitator, Mentor, and Admin all
 * extend this class with the keyword "extends User".
 *
 * NOTIFIABLE: Implements the Notifiable interface so every user
 * type can receive notifications without duplicating that logic.
 */
public abstract class User implements Notifiable {

    // ---- private fields (Encapsulation) ----
    private int userId;
    private String fullName;
    private String email;
    private String phone;
    private String passwordHash;   // no getter — passwords must never be exposed
    private String country;
    private boolean active;
    private boolean consentGiven;
    private int failedLogins;      // counts failed attempts; lock after 3 (FR04)
    private LocalDateTime createdAt;

    // ---- EAC countries allowed to register (FR02) ----
    public static final String[] EAC_COUNTRIES = {
        "Burundi", "DR Congo", "Kenya", "Rwanda",
        "Somalia", "South Sudan", "Tanzania", "Uganda"
    };

    // ---- Constructors ----

    /** Used when creating a new user (before database assigns an ID). */
    public User(String fullName, String email, String phone,
                String passwordHash, String country) {
        this.fullName     = fullName;
        this.email        = email;
        this.phone        = phone;
        this.passwordHash = passwordHash;
        this.country      = country;
        this.active       = true;
        this.consentGiven = false;
        this.failedLogins = 0;
        this.createdAt    = LocalDateTime.now();
    }

    /** Used when loading an existing user from the database. */
    public User(int userId, String fullName, String email, String phone,
                String passwordHash, String country,
                boolean active, boolean consentGiven,
                int failedLogins, LocalDateTime createdAt) {
        this.userId       = userId;
        this.fullName     = fullName;
        this.email        = email;
        this.phone        = phone;
        this.passwordHash = passwordHash;
        this.country      = country;
        this.active       = active;
        this.consentGiven = consentGiven;
        this.failedLogins = failedLogins;
        this.createdAt    = createdAt;
    }

    // ---- Abstract methods — subclasses MUST implement these ----

    /**
     * Returns the role name of this user (e.g. "PARTICIPANT").
     * POLYMORPHISM: each subclass overrides this with @Override.
     */
    public abstract String getRole();

    /**
     * Returns the URL of the dashboard page for this role.
     * POLYMORPHISM: each subclass overrides this with @Override.
     */
    public abstract String getDashboardMenu();

    // ---- Notifiable implementation (shared by all roles) ----

    /**
     * In a production system this would call an SMS/email gateway.
     * For the academic prototype it prints to the server log.
     */
    @Override
    public void sendNotification(String subject, String message) {
        System.out.println("[NOTIFICATION] To: " + email
            + " | Subject: " + subject
            + " | Message: " + message);
    }

    // ---- Getters ----

    public int getUserId()           { return userId; }
    public String getFullName()      { return fullName; }
    public String getEmail()         { return email; }
    public String getPhone()         { return phone; }
    public String getCountry()       { return country; }
    public boolean isActive()        { return active; }
    public boolean isConsentGiven()  { return consentGiven; }
    public int getFailedLogins()     { return failedLogins; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    // passwordHash getter is intentionally omitted for security.
    // Only PasswordUtil should access it via getPasswordHashForVerification().
    public String getPasswordHashForVerification() { return passwordHash; }

    // ---- Setters (with validation where needed) ----

    public void setUserId(int userId)           { this.userId = userId; }
    public void setFullName(String fullName)    { this.fullName = fullName; }
    public void setEmail(String email)          { this.email = email; }
    public void setPhone(String phone)          { this.phone = phone; }
    public void setCountry(String country)      { this.country = country; }
    public void setActive(boolean active)       { this.active = active; }
    public void setConsentGiven(boolean given)  { this.consentGiven = given; }
    public void setPasswordHash(String hash)    { this.passwordHash = hash; }

    public void setFailedLogins(int count) {
        // Clamp to 0–99 to avoid unreasonable values
        this.failedLogins = Math.max(0, Math.min(count, 99));
    }

    /** Increments failed login count by one. */
    public void incrementFailedLogins() {
        this.failedLogins++;
    }

    /** Resets failed login count to zero after a successful login. */
    public void resetFailedLogins() {
        this.failedLogins = 0;
    }

    /**
     * Returns true if the account is locked due to too many failed attempts.
     * The business rule (FR04) locks after 3 failed attempts.
     */
    public boolean isLocked() {
        return failedLogins >= 3;
    }

    @Override
    public String toString() {
        return getRole() + "[" + userId + "] " + fullName + " (" + email + ")";
    }
}
