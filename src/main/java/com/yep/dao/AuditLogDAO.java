package com.yep.dao;

import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * AuditLogDAO — records important system actions for accountability (NFR12).
 *
 * Every significant action (login, promotion, certificate issue) is
 * logged here so administrators can review who did what and when.
 */
public class AuditLogDAO {

    /** One row of the audit log, joined with the user's name for display. */
    public static class Entry {
        private final String userName;
        private final String action;
        private final String detail;
        private final LocalDateTime loggedAt;

        public Entry(String userName, String action, String detail, LocalDateTime loggedAt) {
            this.userName = userName;
            this.action   = action;
            this.detail   = detail;
            this.loggedAt = loggedAt;
        }

        public String getUserName()        { return userName; }
        public String getAction()          { return action; }
        public String getDetail()          { return detail; }
        public LocalDateTime getLoggedAt() { return loggedAt; }

        /** "promote_level2" -> "Promote level2" */
        public String getActionLabel() {
            String s = action.replace('_', ' ');
            return Character.toUpperCase(s.charAt(0)) + s.substring(1);
        }
    }

    /**
     * Logs an action.
     *
     * @param userId the user who performed the action
     * @param action a short label such as "login", "promote_level2", "issue_certificate"
     * @param detail optional extra context (e.g. "Amina Nakato promoted to Level 2")
     */
    public void log(int userId, String action, String detail) {
        String sql = "INSERT INTO audit_log (user_id, action, detail) VALUES (?, ?, ?)";

        // We catch the exception here (instead of throwing it) so a logging
        // failure never interrupts the user's actual action.
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ps.setString(2, action);
            ps.setString(3, detail == null ? null : detail.substring(0, Math.min(detail.length(), 500)));
            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println("[AUDIT] Failed to write audit log: " + e.getMessage());
        }
    }

    /** Returns the most recent log entries, newest first (admin dashboard). */
    public List<Entry> findRecent(int limit) throws SQLException {
        String sql = "SELECT u.full_name, l.action, l.detail, l.logged_at " +
                     "FROM audit_log l JOIN users u ON u.user_id = l.user_id " +
                     "ORDER BY l.log_id DESC LIMIT ?";
        List<Entry> list = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Entry(rs.getString(1), rs.getString(2), rs.getString(3),
                                       rs.getTimestamp(4).toLocalDateTime()));
                }
            }
        }
        return list;
    }
}
