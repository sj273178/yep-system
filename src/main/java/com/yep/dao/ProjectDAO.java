package com.yep.dao;

import com.yep.model.Project;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ProjectDAO — database operations for Impact Projects (FR15, FR16).
 */
public class ProjectDAO {

    /** Creates a new project and returns the generated project_id. */
    public int create(Project project) throws SQLException {
        String sql = "INSERT INTO projects (team_id, title, problem_statement, " +
                     "status, ai_use_declaration) VALUES (?, ?, ?, 'draft', ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, project.getTeamId());
            ps.setString(2, project.getTitle());
            ps.setString(3, project.getProblemStatement());
            ps.setString(4, project.getAiUseDeclaration());
            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    /** Returns the project belonging to a specific team. */
    public Project findByTeam(int teamId) throws SQLException {
        String sql = "SELECT * FROM projects WHERE team_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    /** Returns a project by its ID, or null. */
    public Project findById(int projectId) throws SQLException {
        String sql = "SELECT * FROM projects WHERE project_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, projectId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        }
        return null;
    }

    /** Returns all projects (admin view). */
    public List<Project> findAll() throws SQLException {
        String sql = "SELECT * FROM projects ORDER BY submitted_at DESC";
        List<Project> list = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) list.add(mapRow(rs));
        }
        return list;
    }

    /**
     * Submits a project for mentor review — changes status to "submitted"
     * and records the submission timestamp (FR15).
     */
    public void submit(int projectId) throws SQLException {
        String sql = "UPDATE projects SET status = 'submitted', submitted_at = NOW() " +
                     "WHERE project_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, projectId);
            ps.executeUpdate();
        }
    }

    /**
     * Mentor approves a project or requests a revision (FR16).
     * status must be "approved" or "revision_requested".
     */
    public void review(int projectId, String status, String feedback) throws SQLException {
        String sql = "UPDATE projects SET status = ?, mentor_feedback = ? WHERE project_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, status);
            ps.setString(2, feedback);
            ps.setInt(3, projectId);
            ps.executeUpdate();
        }
    }

    /** Updates the project content while it is still in draft or revision. */
    public void update(Project project) throws SQLException {
        String sql = "UPDATE projects SET title = ?, problem_statement = ?, " +
                     "ai_use_declaration = ? WHERE project_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, project.getTitle());
            ps.setString(2, project.getProblemStatement());
            ps.setString(3, project.getAiUseDeclaration());
            ps.setInt(4, project.getProjectId());
            ps.executeUpdate();
        }
    }

    private Project mapRow(ResultSet rs) throws SQLException {
        Timestamp submittedTs = rs.getTimestamp("submitted_at");
        return new Project(
            rs.getInt("project_id"),
            rs.getInt("team_id"),
            rs.getString("title"),
            rs.getString("problem_statement"),
            rs.getString("status"),
            rs.getString("ai_use_declaration"),
            rs.getString("mentor_feedback"),
            submittedTs != null ? submittedTs.toLocalDateTime() : null
        );
    }
}
