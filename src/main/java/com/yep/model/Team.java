package com.yep.model;

import com.yep.util.YEPException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Team — a Level Two cross-country group of 3 to 5 participants (FR13).
 *
 * ENCAPSULATION: The member list is kept private and getMemberIds()
 * only returns a read-only view. External code must call addMember(),
 * which enforces the business rules before changing the list:
 *   - a team has at most MAX_SIZE members
 *   - only Level Two participants may join
 *   - a participant cannot already be in another team
 */
public class Team {

    public static final int MIN_SIZE = 3;
    public static final int MAX_SIZE = 5;

    /** Focus areas allowed by the database ENUM. */
    public static final String[] FOCUS_AREAS = {
        "employment", "education", "agriculture", "health", "climate", "digital_inclusion"
    };

    private int teamId;
    private String name;
    private String focusArea;      // e.g. "employment", "health"
    private Integer mentorId;      // null until a mentor is assigned
    private LocalDateTime createdAt;

    // The list of participant user IDs in this team
    private final List<Integer> memberIds = new ArrayList<>();

    // ---- Constructors ----

    public Team(String name, String focusArea) {
        this.name       = name;
        this.focusArea  = focusArea;
        this.createdAt  = LocalDateTime.now();
    }

    public Team(int teamId, String name, String focusArea,
                Integer mentorId, LocalDateTime createdAt) {
        this.teamId    = teamId;
        this.name      = name;
        this.focusArea = focusArea;
        this.mentorId  = mentorId;
        this.createdAt = createdAt;
    }

    // ---- Business logic ----

    /**
     * Adds a participant after checking the team rules (report section 6.5).
     * Throws YEPException if any rule is broken.
     */
    public void addMember(Participant p) throws YEPException {
        if (memberIds.size() >= MAX_SIZE)
            throw new YEPException(name + " is already full (max " + MAX_SIZE + " members).");
        if (p.getVeLevel() != 2)
            throw new YEPException(p.getFullName() + " is not a Level Two participant.");
        if (p.getTeamId() != null || memberIds.contains(p.getUserId()))
            throw new YEPException(p.getFullName() + " is already in a team.");
        memberIds.add(p.getUserId());
    }

    /** Used by the DAO when loading an existing team's members from the database. */
    public void loadMember(int participantId) {
        memberIds.add(participantId);
    }

    /** Returns true when the team has at least the minimum 3 members. */
    public boolean isReadyToWork() {
        return memberIds.size() >= MIN_SIZE;
    }

    /** Converts a database value like "digital_inclusion" into "Digital Inclusion". */
    public static String focusLabel(String focusArea) {
        if (focusArea == null || focusArea.isEmpty()) return "";
        StringBuilder sb = new StringBuilder();
        for (String word : focusArea.split("_")) {
            if (sb.length() > 0) sb.append(' ');
            sb.append(Character.toUpperCase(word.charAt(0))).append(word.substring(1));
        }
        return sb.toString();
    }

    public String getFocusLabel() { return focusLabel(focusArea); }

    // ---- Getters ----

    public int getTeamId()                 { return teamId; }
    public String getName()               { return name; }
    public String getFocusArea()          { return focusArea; }
    public Integer getMentorId()          { return mentorId; }
    public LocalDateTime getCreatedAt()   { return createdAt; }
    public List<Integer> getMemberIds()   { return Collections.unmodifiableList(memberIds); }
    public int getMemberCount()           { return memberIds.size(); }

    // ---- Setters ----

    public void setTeamId(int id)          { this.teamId = id; }
    public void setName(String name)       { this.name = name; }
    public void setFocusArea(String area)  { this.focusArea = area; }
    public void setMentorId(Integer id)    { this.mentorId = id; }
}
