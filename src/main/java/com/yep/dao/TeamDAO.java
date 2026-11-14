package com.yep.dao;

import com.yep.model.Team;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * TeamDAO — database operations for Level Two teams.
 *
 * Every team that is loaded also gets its member IDs filled in,
 * so getMemberCount() is always correct.
 */
public class TeamDAO {

    /** Creates a new team and returns the generated team_id. */
    public int create(Team team) throws SQLException {
        String sql = "INSERT INTO teams (name, focus_area) VALUES (?, ?)";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, team.getName());
            ps.setString(2, team.getFocusArea());
            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    /** Assigns a mentor to a team (FR14). */
    public void assignMentor(int teamId, int mentorId) throws SQLException {
        String sql = "UPDATE teams SET mentor_id = ? WHERE team_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, mentorId);
            ps.setInt(2, teamId);
            ps.executeUpdate();
        }
    }

    /** Returns a single team by its ID, or null. */
    public Team findById(int teamId) throws SQLException {
        List<Team> list = query("SELECT * FROM teams WHERE team_id = ?", teamId);
        return list.isEmpty() ? null : list.get(0);
    }

    /** Returns all teams, oldest first. */
    public List<Team> findAll() throws SQLException {
        return query("SELECT * FROM teams ORDER BY team_id");
    }

    /** Returns teams assigned to a specific mentor. */
    public List<Team> findByMentor(int mentorId) throws SQLException {
        return query("SELECT * FROM teams WHERE mentor_id = ? ORDER BY team_id", mentorId);
    }

    /** Counts how many teams are currently assigned to a mentor (FR14). */
    public int countTeamsForMentor(int mentorId) throws SQLException {
        return count("SELECT COUNT(*) FROM teams WHERE mentor_id = ?", mentorId);
    }

    /** Counts all teams (used to number new teams). */
    public int countAll() throws SQLException {
        return count("SELECT COUNT(*) FROM teams");
    }

    // ---- private helpers ----

    private List<Team> query(String sql, Object... params) throws SQLException {
        List<Team> list = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) list.add(mapRow(rs));
                }
            }
            // Load members on the same connection
            String memberSql = "SELECT user_id FROM participants WHERE team_id = ? ORDER BY user_id";
            try (PreparedStatement ps = conn.prepareStatement(memberSql)) {
                for (Team t : list) {
                    ps.setInt(1, t.getTeamId());
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) t.loadMember(rs.getInt(1));
                    }
                }
            }
        }
        return list;
    }

    private int count(String sql, Object... params) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    private Team mapRow(ResultSet rs) throws SQLException {
        int mentorIdInt = rs.getInt("mentor_id");
        Integer mentorId = rs.wasNull() ? null : mentorIdInt;

        return new Team(
            rs.getInt("team_id"),
            rs.getString("name"),
            rs.getString("focus_area"),
            mentorId,
            rs.getTimestamp("created_at").toLocalDateTime()
        );
    }
}
