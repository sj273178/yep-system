package com.yep.model;

/**
 * ParticipantProgress — groups a participant with their progress figures
 * (sessions attended, average score) and certificate status so the admin
 * pages can show everything in one table row.
 *
 * COMPOSITION: a ParticipantProgress HAS-A Participant.
 */
public class ParticipantProgress {

    private final Participant participant;
    private final int sessionsAttended;
    private final double averageScore;
    private final String level1Status;   // null = eligible, otherwise "Already issued" or a reason
    private final String level2Status;

    public ParticipantProgress(Participant participant, int sessionsAttended, double averageScore,
                               String level1Status, String level2Status) {
        this.participant      = participant;
        this.sessionsAttended = sessionsAttended;
        this.averageScore     = averageScore;
        this.level1Status     = level1Status;
        this.level2Status     = level2Status;
    }

    public Participant getParticipant()  { return participant; }
    public int getSessionsAttended()     { return sessionsAttended; }
    public double getAverageScore()      { return averageScore; }
    public String getGrade()             { return Participant.computeGrade(averageScore); }
    public String getLevel1Status()      { return level1Status; }
    public String getLevel2Status()      { return level2Status; }

    public boolean canIssueLevel1()      { return level1Status == null; }
    public boolean canIssueLevel2()      { return level2Status == null; }

    /** CSS badge colour for the grade. */
    public String getGradeBadge() {
        return switch (getGrade()) {
            case "Distinction" -> "badge-green";
            case "Merit"       -> "badge-blue";
            case "Pass"        -> "badge-gold";
            default            -> "badge-red";
        };
    }
}
