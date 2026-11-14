package com.yep.dao;

import com.yep.model.Question;
import com.yep.model.Quiz;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * QuizDAO — database operations for session quiz questions (FR10).
 */
public class QuizDAO {

    /** Loads the quiz for a session (it may have no questions yet). */
    public Quiz findByActivity(int activityId) throws SQLException {
        String sql = "SELECT * FROM quiz_questions WHERE activity_id = ? ORDER BY question_id";
        List<Question> questions = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, activityId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) questions.add(mapRow(rs));
            }
        }
        return new Quiz(activityId, questions);
    }

    /** Returns activity_id -> number of quiz questions, for every session that has a quiz. */
    public Map<Integer, Integer> countQuestionsPerActivity() throws SQLException {
        String sql = "SELECT activity_id, COUNT(*) FROM quiz_questions GROUP BY activity_id";
        Map<Integer, Integer> map = new HashMap<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getInt(1), rs.getInt(2));
        }
        return map;
    }

    /** Adds a question to a session's quiz and returns its new ID. */
    public int add(Question q) throws SQLException {
        String sql = "INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, " +
                     "option_c, option_d, correct_option) VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, q.getActivityId());
            ps.setString(2, q.getText());
            ps.setString(3, q.getOption('A'));
            ps.setString(4, q.getOption('B'));
            ps.setString(5, q.getOption('C'));
            ps.setString(6, q.getOption('D'));
            ps.setString(7, String.valueOf(q.getCorrectOption()));
            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    /** Deletes one question, but only if it belongs to the given session. */
    public void delete(int questionId, int activityId) throws SQLException {
        String sql = "DELETE FROM quiz_questions WHERE question_id = ? AND activity_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, questionId);
            ps.setInt(2, activityId);
            ps.executeUpdate();
        }
    }

    private Question mapRow(ResultSet rs) throws SQLException {
        return new Question(
            rs.getInt("question_id"),
            rs.getInt("activity_id"),
            rs.getString("question_text"),
            rs.getString("option_a"),
            rs.getString("option_b"),
            rs.getString("option_c"),
            rs.getString("option_d"),
            rs.getString("correct_option").charAt(0)
        );
    }
}
