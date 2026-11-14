package com.yep.model;

import java.time.LocalDateTime;

/**
 * Assessment — a quiz or participation score given to a participant
 * for attending a specific activity (FR10).
 *
 * The system uses these scores to compute the participant's average
 * and determine their grade and Level Two eligibility (FR11, FR12).
 */
public class Assessment {

    private int assessmentId;
    private int participantId;
    private int activityId;
    private double score;          // 0.00 – 100.00 (FR10)
    private String type;           // "quiz" or "participation"
    private String comment;
    private int assessorId;        // facilitator who gave this score
    private LocalDateTime assessedAt;

    // ---- Constructors ----

    public Assessment(int participantId, int activityId, double score,
                      String type, String comment, int assessorId) {
        this.participantId = participantId;
        this.activityId    = activityId;
        this.score         = score;
        this.type          = type;
        this.comment       = comment;
        this.assessorId    = assessorId;
        this.assessedAt    = LocalDateTime.now();
    }

    public Assessment(int assessmentId, int participantId, int activityId,
                      double score, String type, String comment,
                      int assessorId, LocalDateTime assessedAt) {
        this.assessmentId  = assessmentId;
        this.participantId = participantId;
        this.activityId    = activityId;
        this.score         = score;
        this.type          = type;
        this.comment       = comment;
        this.assessorId    = assessorId;
        this.assessedAt    = assessedAt;
    }

    // ---- Getters ----

    public int getAssessmentId()        { return assessmentId; }
    public int getParticipantId()       { return participantId; }
    public int getActivityId()          { return activityId; }
    public double getScore()            { return score; }
    public String getType()             { return type; }
    public String getComment()          { return comment; }
    public int getAssessorId()          { return assessorId; }
    public LocalDateTime getAssessedAt(){ return assessedAt; }

    // ---- Setters ----

    public void setAssessmentId(int id)      { this.assessmentId = id; }
    public void setScore(double score)       { this.score = score; }
    public void setComment(String comment)   { this.comment = comment; }
}
