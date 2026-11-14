package com.yep.dao;

import com.yep.model.Message;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * MessageDAO — team discussion messages (FR17).
 */
public class MessageDAO {

    private static final String SELECT =
        "SELECT m.*, u.full_name, u.role, t.name AS team_name " +
        "FROM team_messages m " +
        "JOIN users u ON u.user_id = m.sender_id " +
        "JOIN teams t ON t.team_id = m.team_id ";

    /** Saves a new message. */
    public void send(int teamId, int senderId, String body) throws SQLException {
        String sql = "INSERT INTO team_messages (team_id, sender_id, body) VALUES (?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, teamId);
            ps.setInt(2, senderId);
            ps.setString(3, body);
            ps.executeUpdate();
        }
    }

    /** Returns the latest messages of a team, oldest first (so it reads like a chat). */
    public List<Message> findByTeam(int teamId, int limit) throws SQLException {
        List<Message> list = query(SELECT + "WHERE m.team_id = ? ORDER BY m.message_id DESC LIMIT ?", teamId, limit);
        java.util.Collections.reverse(list);
        return list;
    }

    /** Returns one message, or null. */
    public Message findById(int messageId) throws SQLException {
        List<Message> list = query(SELECT + "WHERE m.message_id = ?", messageId);
        return list.isEmpty() ? null : list.get(0);
    }

    /** All flagged messages, for the admin to review. */
    public List<Message> findFlagged() throws SQLException {
        return query(SELECT + "WHERE m.is_flagged = TRUE ORDER BY m.message_id DESC");
    }

    /** Marks a message as inappropriate or misleading. */
    public void flag(int messageId, int flaggedBy) throws SQLException {
        update("UPDATE team_messages SET is_flagged = TRUE, flagged_by = ? WHERE message_id = ?", flaggedBy, messageId);
    }

    /** Admin decision: the message is fine, so remove the flag. */
    public void clearFlag(int messageId) throws SQLException {
        update("UPDATE team_messages SET is_flagged = FALSE, flagged_by = NULL WHERE message_id = ?", messageId);
    }

    /** Admin decision: the message breaks the rules, so delete it. */
    public void delete(int messageId) throws SQLException {
        update("DELETE FROM team_messages WHERE message_id = ?", messageId);
    }

    // ---- helpers ----

    private List<Message> query(String sql, Object... params) throws SQLException {
        List<Message> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new Message(
                        rs.getInt("message_id"), rs.getInt("team_id"), rs.getInt("sender_id"),
                        rs.getString("full_name"), rs.getString("role"), rs.getString("team_name"),
                        rs.getString("body"), rs.getBoolean("is_flagged"),
                        rs.getTimestamp("sent_at").toLocalDateTime()));
                }
            }
        }
        return list;
    }

    private void update(String sql, Object... params) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            ps.executeUpdate();
        }
    }
}
