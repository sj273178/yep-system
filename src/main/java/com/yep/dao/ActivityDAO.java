package com.yep.dao;

import com.yep.model.Activity;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * ActivityDAO — database operations for Level One sessions (activities).
 */
public class ActivityDAO {

    /** Creates a new session in the database and returns the generated ID. */
    public int create(Activity activity) throws SQLException {
        String sql = "INSERT INTO activities (title, topic, description, session_date, " +
                     "duration_mins, facilitator_id, low_bandwidth, recording_url, notes) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, activity.getTitle());
            ps.setString(2, activity.getTopic());
            ps.setString(3, activity.getDescription());
            ps.setTimestamp(4, Timestamp.valueOf(activity.getSessionDate()));
            ps.setInt(5, activity.getDurationMins());
            ps.setInt(6, activity.getFacilitatorId());
            ps.setBoolean(7, activity.isLowBandwidth());
            ps.setString(8, activity.getRecordingUrl());
            ps.setString(9, activity.getNotes());
            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    /** Returns all activities, most recent first. */
    public List<Activity> findAll() throws SQLException {
        String sql = "SELECT * FROM activities ORDER BY session_date";
        List<Activity> list = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /** Returns activities created by a specific facilitator. */
    public List<Activity> findByFacilitator(int facilitatorId) throws SQLException {
        String sql = "SELECT * FROM activities WHERE facilitator_id = ? ORDER BY session_date DESC";
        List<Activity> list = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, facilitatorId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** Returns a single activity by ID. */
    public Activity findById(int activityId) throws SQLException {
        String sql = "SELECT * FROM activities WHERE activity_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, activityId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    /**
     * Records that a participant attended an activity (FR09).
     * Returns true if a new row was added, false if they had already attended
     * (INSERT IGNORE silently skips duplicates thanks to the composite primary key).
     */
    public boolean recordAttendance(int activityId, int userId, String mode) throws SQLException {
        String sql = "INSERT IGNORE INTO attendance (activity_id, user_id, mode) VALUES (?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, activityId);
            ps.setInt(2, userId);
            ps.setString(3, mode);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Returns the sessions a participant attended as a map of activity_id -> mode
     * ("video", "audio" or "download"). One query instead of one per session.
     */
    public Map<Integer, String> findAttendanceModes(int userId) throws SQLException {
        String sql = "SELECT activity_id, mode FROM attendance WHERE user_id = ?";
        Map<Integer, String> map = new HashMap<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getInt("activity_id"), rs.getString("mode"));
            }
        }
        return map;
    }

    /** Returns activity_id -> number of participants who attended, for every session. */
    public Map<Integer, Integer> countAttendeesPerActivity() throws SQLException {
        String sql = "SELECT activity_id, COUNT(*) FROM attendance GROUP BY activity_id";
        Map<Integer, Integer> map = new HashMap<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getInt(1), rs.getInt(2));
        }
        return map;
    }

    /** Returns true if the participant has already marked attendance for this activity. */
    public boolean hasAttended(int activityId, int userId) throws SQLException {
        String sql = "SELECT 1 FROM attendance WHERE activity_id = ? AND user_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, activityId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Returns the number of activities a participant has attended. */
    public int countAttendance(int userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM attendance WHERE user_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private Activity mapRow(ResultSet rs) throws SQLException {
        Timestamp ts = rs.getTimestamp("session_date");
        Activity activity = new Activity(
            rs.getInt("activity_id"),
            rs.getString("title"),
            rs.getString("topic"),
            rs.getString("description"),
            ts != null ? ts.toLocalDateTime() : null,
            rs.getInt("duration_mins"),
            rs.getInt("facilitator_id"),
            rs.getBoolean("low_bandwidth"),
            rs.getString("recording_url")
        );
        activity.setNotes(rs.getString("notes"));
        return activity;
    }
}
