package com.yep.dao;

import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * ReportDAO — read-only summary queries for the admin reports page (FR21).
 *
 * Reports use aggregated numbers (counts and averages), not individual
 * names, in line with the privacy design in report section 8.2.
 */
public class ReportDAO {

    /** Runs a "SELECT COUNT(*) ..." style query and returns the single number. */
    public int count(String sql) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /** Runs a "SELECT label, COUNT(*) ... GROUP BY label" query and returns label -> count. */
    public Map<String, Integer> grouped(String sql) throws SQLException {
        Map<String, Integer> map = new LinkedHashMap<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getString(1), rs.getInt(2));
        }
        return map;
    }

    public int totalParticipants() throws SQLException {
        return count("SELECT COUNT(*) FROM users WHERE role = 'PARTICIPANT'");
    }

    public int totalStaff() throws SQLException {
        return count("SELECT COUNT(*) FROM users WHERE role <> 'PARTICIPANT'");
    }

    public int sessionsHeld() throws SQLException {
        return count("SELECT COUNT(*) FROM activities");
    }

    public int attendanceRecords() throws SQLException {
        return count("SELECT COUNT(*) FROM attendance");
    }

    public int certificatesIssued() throws SQLException {
        return count("SELECT COUNT(*) FROM certificates");
    }

    public int teams() throws SQLException {
        return count("SELECT COUNT(*) FROM teams");
    }

    public double overallAverageScore() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT AVG(score) FROM assessments");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getDouble(1) : 0.0;
        }
    }

    public Map<String, Integer> participantsByCountry() throws SQLException {
        return grouped("SELECT country, COUNT(*) FROM users WHERE role = 'PARTICIPANT' " +
                       "GROUP BY country ORDER BY COUNT(*) DESC, country");
    }

    public Map<String, Integer> participantsByGender() throws SQLException {
        return grouped("SELECT gender, COUNT(*) FROM participants GROUP BY gender ORDER BY gender");
    }

    public Map<String, Integer> participantsByLevel() throws SQLException {
        return grouped("SELECT CONCAT('Level ', ve_level), COUNT(*) FROM participants " +
                       "GROUP BY ve_level ORDER BY ve_level");
    }

    public Map<String, Integer> attendanceByMode() throws SQLException {
        return grouped("SELECT mode, COUNT(*) FROM attendance GROUP BY mode ORDER BY COUNT(*) DESC");
    }

    public Map<String, Integer> certificatesByType() throws SQLException {
        return grouped("SELECT cert_type, COUNT(*) FROM certificates GROUP BY cert_type ORDER BY cert_type");
    }

    public Map<String, Integer> projectsByStatus() throws SQLException {
        return grouped("SELECT status, COUNT(*) FROM projects GROUP BY status ORDER BY status");
    }
}
