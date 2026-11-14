package com.yep.model;

import java.time.LocalDateTime;

/**
 * Message — one post in a team's discussion board (FR17).
 *
 * Any team member, the team's mentor or an admin can flag a message as
 * inappropriate or misleading. Flagged messages are hidden behind a
 * warning and appear on the admin dashboard for review.
 */
public class Message {

    /** Longest message allowed (matches the database column). */
    public static final int MAX_LENGTH = 1000;

    private int messageId;
    private int teamId;
    private int senderId;
    private String senderName;    // filled from a JOIN, for display only
    private String senderRole;
    private String teamName;      // used on the admin's flagged-messages list
    private String body;
    private boolean flagged;
    private LocalDateTime sentAt;

    public Message(int messageId, int teamId, int senderId, String senderName, String senderRole,
                   String teamName, String body, boolean flagged, LocalDateTime sentAt) {
        this.messageId  = messageId;
        this.teamId     = teamId;
        this.senderId   = senderId;
        this.senderName = senderName;
        this.senderRole = senderRole;
        this.teamName   = teamName;
        this.body       = body;
        this.flagged    = flagged;
        this.sentAt     = sentAt;
    }

    /** True if this message was written by the given user (shown on the right, like WhatsApp). */
    public boolean isFrom(User user) {
        return user != null && user.getUserId() == senderId;
    }

    public int getMessageId()          { return messageId; }
    public int getTeamId()             { return teamId; }
    public int getSenderId()           { return senderId; }
    public String getSenderName()      { return senderName; }
    public String getSenderRole()      { return senderRole; }
    public String getTeamName()        { return teamName; }
    public String getBody()            { return body; }
    public boolean isFlagged()         { return flagged; }
    public LocalDateTime getSentAt()   { return sentAt; }
}
