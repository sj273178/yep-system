package com.yep.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;

/**
 * Participant — represents a youth aged 18-35 from an EAC country.
 *
 * INHERITANCE: Participant IS-A User, so it extends User and inherits
 * all common fields (name, email, country, etc.) without repeating them.
 * It adds participant-specific details like date of birth and VE level.
 *
 * POLYMORPHISM: getRole() and getDashboardMenu() are overridden here
 * using @Override so the system can treat any User polymorphically and
 * still get the right role-specific behaviour.
 */
public class Participant extends User {

    // ---- Programme rules (kept in one place so every class uses the same numbers) ----

    /** Sessions a participant must attend for promotion and the Level One certificate (FR12, FR19). */
    public static final int MIN_SESSIONS = 3;
    /** Average score needed to be promoted to Level Two (FR12). */
    public static final double PROMOTION_AVERAGE = 60.0;
    /** Average score needed for the Level One certificate (UC-12). */
    public static final double CERTIFICATE_AVERAGE = 50.0;
    /** Participation points awarded for each session attended (FR09). */
    public static final int POINTS_PER_SESSION = 10;

    // Participant-specific private fields
    private int veLevel;          // 1 = Level One, 2 = Level Two
    private int points;           // participation points earned
    private Integer teamId;       // null until promoted to Level Two
    private LocalDate dateOfBirth;
    private String gender;        // Male, Female, Other
    private String district;
    private String educationLevel;
    private boolean hasDisability;

    // Skills portfolio (FR23) — only visible to employers when portfolioPublic is true
    private String bio;
    private String skills;            // comma-separated, e.g. "Excel, Canva, Public speaking"
    private String portfolioLink;
    private boolean portfolioPublic;

    // ---- Constructors ----

    /** Used when registering a new participant. */
    public Participant(String fullName, String email, String phone,
                       String passwordHash, String country,
                       LocalDate dateOfBirth, String gender,
                       String district, String educationLevel) {
        // Call the parent (User) constructor to set common fields
        super(fullName, email, phone, passwordHash, country);
        this.veLevel       = 1;    // all participants start at Level One
        this.points        = 0;
        this.teamId        = null;
        this.dateOfBirth   = dateOfBirth;
        this.gender        = gender;
        this.district      = district;
        this.educationLevel = educationLevel;
        this.hasDisability = false;
    }

    /** Used when loading an existing participant from the database. */
    public Participant(int userId, String fullName, String email, String phone,
                       String passwordHash, String country,
                       boolean active, boolean consentGiven,
                       int failedLogins, LocalDateTime createdAt,
                       int veLevel, int points, Integer teamId,
                       LocalDate dateOfBirth, String gender,
                       String district, String educationLevel, boolean hasDisability) {
        super(userId, fullName, email, phone, passwordHash, country,
              active, consentGiven, failedLogins, createdAt);
        this.veLevel        = veLevel;
        this.points         = points;
        this.teamId         = teamId;
        this.dateOfBirth    = dateOfBirth;
        this.gender         = gender;
        this.district       = district;
        this.educationLevel = educationLevel;
        this.hasDisability  = hasDisability;
    }

    // ---- Overriding abstract methods from User (Polymorphism) ----

    @Override
    public String getRole() {
        return "PARTICIPANT";
    }

    @Override
    public String getDashboardMenu() {
        return "/participant/dashboard.jsp";
    }

    // ---- Business logic methods ----

    /**
     * Calculates the participant's current age from their date of birth.
     * Used by FR02 to enforce the 18-35 age rule.
     */
    public int getAge() {
        return Period.between(dateOfBirth, LocalDate.now()).getYears();
    }

    /**
     * Returns the grade label based on the average score (FR11).
     * Distinction: 85-100, Merit: 70-84, Pass: 50-69, Not Yet Competent: 0-49
     */
    public static String computeGrade(double averageScore) {
        if (averageScore >= 85) return "Distinction";
        if (averageScore >= 70) return "Merit";
        if (averageScore >= 50) return "Pass";
        return "Not Yet Competent";
    }

    /**
     * Level Two promotion rule (FR12): still on Level One, at least
     * MIN_SESSIONS attended and an average of at least PROMOTION_AVERAGE.
     * A simple, transparent rule that youth can understand (NFR11).
     */
    public boolean isEligibleForPromotion(int sessionsAttended, double averageScore) {
        return veLevel == 1
            && sessionsAttended >= MIN_SESSIONS
            && averageScore >= PROMOTION_AVERAGE;
    }

    /** Moves the participant to Level Two. */
    public void promoteToLevelTwo() {
        this.veLevel = 2;
    }

    // ---- Getters ----

    public int getVeLevel()          { return veLevel; }
    public int getPoints()           { return points; }
    public Integer getTeamId()       { return teamId; }
    public LocalDate getDateOfBirth(){ return dateOfBirth; }
    public String getGender()        { return gender; }
    public String getDistrict()      { return district; }
    public String getEducationLevel(){ return educationLevel; }
    public boolean isHasDisability() { return hasDisability; }

    // ---- Setters ----

    public void setVeLevel(int veLevel)              { this.veLevel = veLevel; }
    public void setPoints(int points)                { this.points = points; }
    public void setTeamId(Integer teamId)            { this.teamId = teamId; }
    public void setDateOfBirth(LocalDate dob)        { this.dateOfBirth = dob; }
    public void setGender(String gender)             { this.gender = gender; }
    public void setDistrict(String district)         { this.district = district; }
    public void setEducationLevel(String level)      { this.educationLevel = level; }
    public void setHasDisability(boolean disability) { this.hasDisability = disability; }

    // ---- Portfolio (FR23) ----

    public String getBio()            { return bio; }
    public String getSkills()         { return skills; }
    public String getPortfolioLink()  { return portfolioLink; }
    public boolean isPortfolioPublic(){ return portfolioPublic; }

    public void setBio(String bio)                       { this.bio = bio; }
    public void setSkills(String skills)                 { this.skills = skills; }
    public void setPortfolioLink(String link)            { this.portfolioLink = link; }
    public void setPortfolioPublic(boolean visible)      { this.portfolioPublic = visible; }

    /** Splits the comma-separated skills into a list, e.g. for showing as tags. */
    public java.util.List<String> getSkillList() {
        java.util.List<String> list = new java.util.ArrayList<>();
        if (skills == null) return list;
        for (String s : skills.split(",")) {
            if (!s.isBlank()) list.add(s.trim());
        }
        return list;
    }
}
