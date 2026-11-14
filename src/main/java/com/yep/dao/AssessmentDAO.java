package com.yep.dao;

import com.yep.model.Assessment;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * AssessmentDAO — database operations for quiz and participation scores.
 */
public class AssessmentDAO {

    /**
     * Saves a score (FR10). Each participant has at most one score of each
     * type per session (UNIQUE key in the schema), so if the facilitator
     * enters a score again it replaces the old one instead of adding a duplicate.
     *
     * Returns true if a new score was created, false if an existing one was updated.
     */
    public boolean saveOrUpdate(Assessment a) throws SQLException {
        String sql = "INSERT INTO assessments (participant_id, activity_id, score, type, comment, assessor_id) " +
                     "VALUES (?, ?, ?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE score = VALUES(score), comment = VALUES(comment), " +
                     "assessor_id = VALUES(assessor_id), assessed_at = NOW()";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, a.getParticipantId());
            ps.setInt(2, a.getActivityId());
            ps.setDouble(3, a.getScore());
            ps.setString(4, a.getType());
            ps.setString(5, a.getComment());
            ps.setInt(6, a.getAssessorId());
            // MySQL returns 1 for a new row and 2 for an updated row
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Saves an auto-graded quiz result. ONE ATTEMPT per session: the UNIQUE
     * key (participant, activity, type) means a second attempt is not saved.
     *
     * Returns true if saved, false if the participant had already taken this quiz.
     */
    public boolean saveQuizAttempt(Assessment a) throws SQLException {
        String sql = "INSERT IGNORE INTO assessments (participant_id, activity_id, score, type, comment, assessor_id) " +
                     "VALUES (?, ?, ?, 'quiz', ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, a.getParticipantId());
            ps.setInt(2, a.getActivityId());
            ps.setDouble(3, a.getScore());
            ps.setString(4, a.getComment());
            ps.setInt(5, a.getAssessorId());
            return ps.executeUpdate() == 1;
        }
    }

    /** Returns one participant's score of the given type for a session, or null. */
    public Assessment find(int participantId, int activityId, String type) throws SQLException {
        String sql = "SELECT * FROM assessments WHERE participant_id = ? AND activity_id = ? AND type = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, participantId);
            ps.setInt(2, activityId);
            ps.setString(3, type);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** Returns activity_id -> quiz score for every quiz this participant has taken. */
    public java.util.Map<Integer, Double> findQuizScores(int participantId) throws SQLException {
        java.util.Map<Integer, Double> map = new java.util.HashMap<>();
        for (Assessment a : findByParticipant(participantId)) {
            if ("quiz".equals(a.getType())) map.put(a.getActivityId(), a.getScore());
        }
        return map;
    }

    /** True if anyone has already taken the quiz for this session (then its questions are locked). */
    public boolean anyQuizTaken(int activityId) throws SQLException {
        String sql = "SELECT 1 FROM assessments WHERE activity_id = ? AND type = 'quiz' LIMIT 1";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, activityId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Returns all assessments for a given participant. */
    public List<Assessment> findByParticipant(int participantId) throws SQLException {
        return query("SELECT * FROM assessments WHERE participant_id = ? ORDER BY assessed_at DESC", participantId);
    }

    /** Returns all assessments for a given activity (so the facilitator can see all scores). */
    public List<Assessment> findByActivity(int activityId) throws SQLException {
        return query("SELECT * FROM assessments WHERE activity_id = ? ORDER BY assessed_at", activityId);
    }

    /** Counts the scores recorded by one facilitator. */
    public int countByAssessor(int assessorId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM assessments WHERE assessor_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, assessorId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    /**
     * Calculates the average score for a participant across all their assessments.
     * Returns 0.0 if the participant has no assessments yet.
     * Used by FR11 to compute grades and by FR12 to check Level Two eligibility.
     */
    public double getAverageScore(int participantId) throws SQLException {
        String sql = "SELECT AVG(score) FROM assessments WHERE participant_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, participantId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    double avg = rs.getDouble(1);
                    return rs.wasNull() ? 0.0 : avg;
                }
            }
        }
        return 0.0;
    }

    private List<Assessment> query(String sql, int id) throws SQLException {
        List<Assessment> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        }
        return list;
    }

    private Assessment mapRow(ResultSet rs) throws SQLException {
        return new Assessment(
            rs.getInt("assessment_id"),
            rs.getInt("participant_id"),
            rs.getInt("activity_id"),
            rs.getDouble("score"),
            rs.getString("type"),
            rs.getString("comment"),
            rs.getInt("assessor_id"),
            rs.getTimestamp("assessed_at").toLocalDateTime()
        );
    }
}
