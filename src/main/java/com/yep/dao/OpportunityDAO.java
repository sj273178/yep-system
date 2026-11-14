package com.yep.dao;

import com.yep.model.Opportunity;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * OpportunityDAO — internships and challenges from partner organisations (FR24).
 */
public class OpportunityDAO {

    /** Returns every opportunity, the soonest deadline first. */
    public List<Opportunity> findAll() throws SQLException {
        String sql = "SELECT * FROM opportunities ORDER BY deadline";
        List<Opportunity> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Opportunity(
                    rs.getInt("opportunity_id"), rs.getString("title"), rs.getString("organisation"),
                    rs.getString("opp_type"), rs.getString("description"), rs.getString("country"),
                    rs.getDate("deadline").toLocalDate(), rs.getString("apply_link")));
            }
        }
        return list;
    }

    /** Adds a new opportunity. */
    public void create(String title, String organisation, String type, String description,
                       String country, LocalDate deadline, String applyLink, int postedBy) throws SQLException {
        String sql = "INSERT INTO opportunities (title, organisation, opp_type, description, country, " +
                     "deadline, apply_link, posted_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title);
            ps.setString(2, organisation);
            ps.setString(3, type);
            ps.setString(4, description);
            ps.setString(5, country);
            ps.setDate(6, Date.valueOf(deadline));
            ps.setString(7, applyLink);
            ps.setInt(8, postedBy);
            ps.executeUpdate();
        }
    }

    /** Removes an opportunity. */
    public void delete(int opportunityId) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM opportunities WHERE opportunity_id = ?")) {
            ps.setInt(1, opportunityId);
            ps.executeUpdate();
        }
    }
}
