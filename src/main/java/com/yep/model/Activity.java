package com.yep.model;

import java.time.LocalDateTime;

/**
 * Activity — a Level One learning session created by a Facilitator (FR07).
 *
 * Each Activity has a title, topic, date, duration, and an optional
 * low-bandwidth mode so participants with slow connections can still attend.
 */
public class Activity {

    private int activityId;
    private String title;
    private String topic;
    private String description;
    private LocalDateTime sessionDate;
    private int durationMins;
    private int facilitatorId;
    private boolean lowBandwidth;   // true = audio-only / download option available
    private String recordingUrl;   // optional link to the video/audio recording
    private String notes;          // short learning notes (low-data option, FR08)

    // ---- Constructors ----

    /** Used when a facilitator creates a new session. */
    public Activity(String title, String topic, String description,
                    LocalDateTime sessionDate, int durationMins,
                    int facilitatorId, boolean lowBandwidth) {
        this.title         = title;
        this.topic         = topic;
        this.description   = description;
        this.sessionDate   = sessionDate;
        this.durationMins  = durationMins;
        this.facilitatorId = facilitatorId;
        this.lowBandwidth  = lowBandwidth;
    }

    /** Used when loading from the database. */
    public Activity(int activityId, String title, String topic, String description,
                    LocalDateTime sessionDate, int durationMins,
                    int facilitatorId, boolean lowBandwidth, String recordingUrl) {
        this.activityId    = activityId;
        this.title         = title;
        this.topic         = topic;
        this.description   = description;
        this.sessionDate   = sessionDate;
        this.durationMins  = durationMins;
        this.facilitatorId = facilitatorId;
        this.lowBandwidth  = lowBandwidth;
        this.recordingUrl  = recordingUrl;
    }

    // ---- Getters ----

    public int getActivityId()         { return activityId; }
    public String getTitle()           { return title; }
    public String getTopic()           { return topic; }
    public String getDescription()     { return description; }
    public LocalDateTime getSessionDate() { return sessionDate; }
    public int getDurationMins()       { return durationMins; }
    public int getFacilitatorId()      { return facilitatorId; }
    public boolean isLowBandwidth()    { return lowBandwidth; }
    public String getRecordingUrl()    { return recordingUrl; }
    public String getNotes()           { return notes; }

    /**
     * A session can be completed (attended and quiz taken) once it has started.
     * Recordings and notes stay available afterwards, so youth who missed the
     * live session because of power or data problems can still complete it (report 10.1).
     */
    public boolean hasStarted() {
        return sessionDate != null && !sessionDate.isAfter(LocalDateTime.now());
    }

    // ---- Setters ----

    public void setActivityId(int id)          { this.activityId = id; }
    public void setTitle(String title)         { this.title = title; }
    public void setTopic(String topic)         { this.topic = topic; }
    public void setDescription(String desc)    { this.description = desc; }
    public void setSessionDate(LocalDateTime d){ this.sessionDate = d; }
    public void setDurationMins(int mins)      { this.durationMins = mins; }
    public void setLowBandwidth(boolean lb)    { this.lowBandwidth = lb; }
    public void setRecordingUrl(String url)    { this.recordingUrl = url; }
    public void setNotes(String notes)         { this.notes = notes; }
}
