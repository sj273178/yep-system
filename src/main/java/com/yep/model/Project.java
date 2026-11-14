package com.yep.model;

import java.time.LocalDateTime;

/**
 * Project — the Impact Project developed by a Level Two team (FR15).
 *
 * Each team may have exactly one project. The project moves through
 * three statuses: draft → submitted → approved (or revision_requested).
 *
 * An AI-use declaration is mandatory before submission (FR15, NFR11).
 */
public class Project {

    // Status values as constants to avoid typos throughout the code
    public static final String STATUS_DRAFT              = "draft";
    public static final String STATUS_SUBMITTED          = "submitted";
    public static final String STATUS_APPROVED           = "approved";
    public static final String STATUS_REVISION_REQUESTED = "revision_requested";

    private int projectId;
    private int teamId;
    private String title;
    private String problemStatement;
    private String status;
    private String aiUseDeclaration;   // what AI tools the team used (FR15, NFR11)
    private String mentorFeedback;
    private LocalDateTime submittedAt;

    // ---- Constructors ----

    public Project(int teamId, String title, String problemStatement,
                   String aiUseDeclaration) {
        this.teamId            = teamId;
        this.title             = title;
        this.problemStatement  = problemStatement;
        this.aiUseDeclaration  = aiUseDeclaration;
        this.status            = STATUS_DRAFT;
    }

    public Project(int projectId, int teamId, String title,
                   String problemStatement, String status,
                   String aiUseDeclaration, String mentorFeedback,
                   LocalDateTime submittedAt) {
        this.projectId         = projectId;
        this.teamId            = teamId;
        this.title             = title;
        this.problemStatement  = problemStatement;
        this.status            = status;
        this.aiUseDeclaration  = aiUseDeclaration;
        this.mentorFeedback    = mentorFeedback;
        this.submittedAt       = submittedAt;
    }

    // ---- Business logic ----

    /** The team may only edit while the project is a draft or has been sent back for revision. */
    public boolean isEditable() {
        return STATUS_DRAFT.equals(status) || STATUS_REVISION_REQUESTED.equals(status);
    }

    /** "revision_requested" -> "Revision Requested" */
    public String getStatusLabel() {
        return switch (status) {
            case STATUS_DRAFT              -> "Draft";
            case STATUS_SUBMITTED          -> "Submitted";
            case STATUS_APPROVED           -> "Approved";
            case STATUS_REVISION_REQUESTED -> "Revision Requested";
            default                        -> status;
        };
    }

    /** CSS badge colour for the status. */
    public String getStatusBadge() {
        return switch (status) {
            case STATUS_APPROVED           -> "badge-green";
            case STATUS_SUBMITTED          -> "badge-blue";
            case STATUS_REVISION_REQUESTED -> "badge-gold";
            default                        -> "badge-grey";
        };
    }

    // ---- Getters ----

    public int getProjectId()             { return projectId; }
    public int getTeamId()                 { return teamId; }
    public String getTitle()               { return title; }
    public String getProblemStatement()    { return problemStatement; }
    public String getStatus()             { return status; }
    public String getAiUseDeclaration()   { return aiUseDeclaration; }
    public String getMentorFeedback()     { return mentorFeedback; }
    public LocalDateTime getSubmittedAt() { return submittedAt; }

    // ---- Setters ----

    public void setProjectId(int id)                   { this.projectId = id; }
    public void setTitle(String title)                 { this.title = title; }
    public void setProblemStatement(String ps)         { this.problemStatement = ps; }
    public void setStatus(String status)               { this.status = status; }
    public void setAiUseDeclaration(String decl)       { this.aiUseDeclaration = decl; }
    public void setMentorFeedback(String feedback)     { this.mentorFeedback = feedback; }
    public void setSubmittedAt(LocalDateTime submitted){ this.submittedAt = submitted; }
}
