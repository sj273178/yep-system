package com.yep.dao;

import com.yep.model.*;
import com.yep.util.DatabaseConnection;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * UserDAO — Data Access Object for all user-related database operations.
 *
 * HOW DAO PATTERN WORKS:
 *   The DAO sits between the servlet and the database. Servlets call
 *   UserDAO methods (createParticipant, findByEmail, etc.) and never
 *   write SQL themselves. This keeps SQL in one place and makes it easy
 *   to change the database without touching the servlet code.
 *
 * HOW PreparedStatement WORKS:
 *   Instead of building a SQL string with + operators (which opens the
 *   door to SQL injection), we use ? placeholders and set each value
 *   separately. The JDBC driver ensures the values are safely escaped.
 *
 *   Example of SQL injection risk (BAD — never do this):
 *     "SELECT * FROM users WHERE email = '" + email + "'"
 *
 *   Safe with PreparedStatement (GOOD):
 *     "SELECT * FROM users WHERE email = ?"
 *     ps.setString(1, email);
 */
public class UserDAO {

    /**
     * One SELECT used by every "find" method. It joins the users supertype
     * table with all subtype tables so mapRowToUser() can build the right
     * subclass (Participant, Facilitator, Mentor or Admin).
     */
    private static final String SELECT_USER =
        "SELECT u.*, " +
        "       p.ve_level, p.points, p.team_id, p.date_of_birth, p.gender, " +
        "       p.district, p.education_level, p.has_disability, " +
        "       p.bio, p.skills, p.portfolio_link, p.portfolio_public, " +
        "       f.organisation, m.expertise, m.max_teams " +
        "FROM users u " +
        "LEFT JOIN participants p ON u.user_id = p.user_id " +
        "LEFT JOIN facilitators f ON u.user_id = f.user_id " +
        "LEFT JOIN mentors      m ON u.user_id = m.user_id ";

    // ----------------------------------------------------------------
    // CREATE
    // ----------------------------------------------------------------

    /**
     * Inserts a new participant into the users and participants tables.
     * Uses a transaction so both inserts succeed or both are rolled back.
     */
    public int createParticipant(Participant p) throws SQLException {
        String partSql = "INSERT INTO participants (user_id, ve_level, points, " +
                         "date_of_birth, gender, district, education_level, has_disability) " +
                         "VALUES (?, 1, 0, ?, ?, ?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);   // start transaction
            try {
                int userId = insertUserRow(conn, p, p.isConsentGiven());

                try (PreparedStatement ps = conn.prepareStatement(partSql)) {
                    ps.setInt(1, userId);
                    ps.setDate(2, Date.valueOf(p.getDateOfBirth()));
                    ps.setString(3, p.getGender());
                    ps.setString(4, p.getDistrict());
                    ps.setString(5, p.getEducationLevel());
                    ps.setBoolean(6, p.isHasDisability());
                    ps.executeUpdate();
                }
                conn.commit();   // both inserts succeeded — commit the transaction
                return userId;
            } catch (SQLException e) {
                conn.rollback(); // undo the half-finished registration
                throw e;
            }
        }
    }

    /** Inserts a new facilitator into the users and facilitators tables (FR22). */
    public int createFacilitator(Facilitator f) throws SQLException {
        String facSql = "INSERT INTO facilitators (user_id, organisation) VALUES (?, ?)";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int userId = insertUserRow(conn, f, true);
                try (PreparedStatement ps = conn.prepareStatement(facSql)) {
                    ps.setInt(1, userId);
                    ps.setString(2, f.getOrganisation());
                    ps.executeUpdate();
                }
                conn.commit();
                return userId;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        }
    }

    /** Inserts a new mentor into the users and mentors tables (FR22). */
    public int createMentor(Mentor m) throws SQLException {
        String menSql = "INSERT INTO mentors (user_id, expertise, max_teams) VALUES (?, ?, ?)";

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int userId = insertUserRow(conn, m, true);
                try (PreparedStatement ps = conn.prepareStatement(menSql)) {
                    ps.setInt(1, userId);
                    ps.setString(2, m.getExpertise());
                    ps.setInt(3, m.getMaxTeams());
                    ps.executeUpdate();
                }
                conn.commit();
                return userId;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        }
    }

    /**
     * Inserts the common users row. getRole() is called polymorphically,
     * so the same code works for every subclass of User.
     */
    private int insertUserRow(Connection conn, User u, boolean consent) throws SQLException {
        String sql = "INSERT INTO users (full_name, email, phone, password_hash, " +
                     "country, role, is_active, consent_given) VALUES (?, ?, ?, ?, ?, ?, TRUE, ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, u.getFullName());
            ps.setString(2, u.getEmail());
            ps.setString(3, u.getPhone());
            ps.setString(4, u.getPasswordHashForVerification());
            ps.setString(5, u.getCountry());
            ps.setString(6, u.getRole());
            ps.setBoolean(7, consent);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    // ----------------------------------------------------------------
    // READ
    // ----------------------------------------------------------------

    /**
     * Finds a user by email address (used during login).
     * Returns null if no matching user is found.
     */
    public User findByEmail(String email) throws SQLException {
        List<User> list = queryUsers(SELECT_USER + "WHERE u.email = ?", email);
        return list.isEmpty() ? null : list.get(0);
    }

    /** Finds a user by their primary key (user_id). */
    public User findById(int userId) throws SQLException {
        List<User> list = queryUsers(SELECT_USER + "WHERE u.user_id = ?", userId);
        return list.isEmpty() ? null : list.get(0);
    }

    /** Returns all users (for the admin management page, FR22). */
    public List<User> findAll() throws SQLException {
        return queryUsers(SELECT_USER + "ORDER BY u.role, u.full_name");
    }

    /** Returns every participant, sorted by name (used by the certificates page). */
    public List<Participant> findAllParticipants() throws SQLException {
        return toParticipants(queryUsers(SELECT_USER + "WHERE u.role = 'PARTICIPANT' ORDER BY u.full_name"));
    }

    /** Returns the members of a team (FR13). */
    public List<Participant> findByTeam(int teamId) throws SQLException {
        return toParticipants(queryUsers(SELECT_USER + "WHERE p.team_id = ? ORDER BY u.full_name", teamId));
    }

    /** Returns the participants who attended a session, so a facilitator can score them (FR10). */
    public List<Participant> findAttendees(int activityId) throws SQLException {
        return toParticipants(queryUsers(SELECT_USER +
            "JOIN attendance a ON a.user_id = u.user_id " +
            "WHERE a.activity_id = ? ORDER BY u.full_name", activityId));
    }

    /**
     * Returns all participants who qualify for Level Two promotion (FR12):
     * still at Level One, attended at least MIN_SESSIONS activities and an
     * average assessment score of at least PROMOTION_AVERAGE.
     */
    public List<Participant> findEligibleForPromotion() throws SQLException {
        String sql = SELECT_USER +
            "WHERE u.role = 'PARTICIPANT' AND p.ve_level = 1 AND u.is_active = TRUE " +
            "  AND (SELECT COUNT(*) FROM attendance a WHERE a.user_id = u.user_id) >= ? " +
            "  AND (SELECT AVG(score) FROM assessments s WHERE s.participant_id = u.user_id) >= ? " +
            "ORDER BY u.full_name";
        return toParticipants(queryUsers(sql, Participant.MIN_SESSIONS, Participant.PROMOTION_AVERAGE));
    }

    /** Returns all active Level Two participants who do not yet have a team (FR13). */
    public List<Participant> findLevel2WithoutTeam() throws SQLException {
        return toParticipants(queryUsers(SELECT_USER +
            "WHERE p.ve_level = 2 AND p.team_id IS NULL AND u.is_active = TRUE ORDER BY u.country"));
    }

    /** Returns every active mentor (with how many teams each already has, via TeamDAO). */
    public List<Mentor> findMentors() throws SQLException {
        List<Mentor> mentors = new ArrayList<>();
        for (User u : queryUsers(SELECT_USER + "WHERE u.role = 'MENTOR' AND u.is_active = TRUE ORDER BY u.full_name")) {
            mentors.add((Mentor) u);
        }
        return mentors;
    }

    /** Checks whether an email address is already registered (FR02). */
    public boolean emailExists(String email) throws SQLException {
        String sql = "SELECT 1 FROM users WHERE email = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // ----------------------------------------------------------------
    // UPDATE
    // ----------------------------------------------------------------

    /** Updates the failed_logins counter after a failed login attempt. */
    public void updateFailedLogins(int userId, int count) throws SQLException {
        executeUpdate("UPDATE users SET failed_logins = ? WHERE user_id = ?", count, userId);
    }

    /** Activates or deactivates a user account (FR22). Activating also clears any lock-out. */
    public void setActiveStatus(int userId, boolean active) throws SQLException {
        if (active) {
            executeUpdate("UPDATE users SET is_active = TRUE, failed_logins = 0 WHERE user_id = ?", userId);
        } else {
            executeUpdate("UPDATE users SET is_active = FALSE WHERE user_id = ?", userId);
        }
    }

    /** Promotes a participant to Level Two (FR12). */
    public void promoteToLevelTwo(int userId) throws SQLException {
        executeUpdate("UPDATE participants SET ve_level = 2 WHERE user_id = ?", userId);
    }

    /** Assigns a participant to a team (FR13). */
    public void assignTeam(int userId, int teamId) throws SQLException {
        executeUpdate("UPDATE participants SET team_id = ? WHERE user_id = ?", teamId, userId);
    }

    /** Adds participation points to a participant (FR09). */
    public void addPoints(int userId, int points) throws SQLException {
        executeUpdate("UPDATE participants SET points = points + ? WHERE user_id = ?", points, userId);
    }

    // ----------------------------------------------------------------
    // PROFILE, PORTFOLIO AND PRIVACY (FR05, FR23, NFR Privacy)
    // ----------------------------------------------------------------

    /** Returns participants who chose to show their portfolio to employers (FR23). */
    public List<Participant> findPublicPortfolios() throws SQLException {
        return toParticipants(queryUsers(SELECT_USER +
            "WHERE u.role = 'PARTICIPANT' AND u.is_active = TRUE AND p.portfolio_public = TRUE " +
            "ORDER BY p.ve_level DESC, u.full_name"));
    }

    /** Lets a user correct their own contact details. */
    public void updateContact(int userId, String phone) throws SQLException {
        executeUpdate("UPDATE users SET phone = ? WHERE user_id = ?", phone, userId);
    }

    /** Saves a participant's district and skills portfolio (FR23). */
    public void updatePortfolio(Participant p) throws SQLException {
        executeUpdate("UPDATE participants SET district = ?, bio = ?, skills = ?, portfolio_link = ?, " +
                      "portfolio_public = ? WHERE user_id = ?",
            p.getDistrict(), p.getBio(), p.getSkills(), p.getPortfolioLink(),
            p.isPortfolioPublic(), p.getUserId());
    }

    /** Sets a new password and clears any lock-out and reset code. */
    public void updatePassword(int userId, String newHash) throws SQLException {
        executeUpdate("UPDATE users SET password_hash = ?, failed_logins = 0, " +
                      "reset_code_hash = NULL, reset_expires = NULL WHERE user_id = ?", newHash, userId);
    }

    /** Stores the hashed one-time reset code and when it expires (FR05). */
    public void saveResetCode(int userId, String codeHash, java.time.LocalDateTime expires) throws SQLException {
        executeUpdate("UPDATE users SET reset_code_hash = ?, reset_expires = ? WHERE user_id = ?",
            codeHash, Timestamp.valueOf(expires), userId);
    }

    /**
     * Returns {codeHash, expires} for the user's reset code, or null if no
     * code was requested. Kept out of the User object on purpose.
     */
    public Object[] findResetCode(int userId) throws SQLException {
        String sql = "SELECT reset_code_hash, reset_expires FROM users WHERE user_id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next() || rs.getString(1) == null) return null;
                return new Object[] { rs.getString(1), rs.getTimestamp(2).toLocalDateTime() };
            }
        }
    }

    /**
     * "Delete my data" (Data Protection and Privacy Act 2019).
     * Scores and attendance must stay for programme reports, so instead of
     * deleting the row we ANONYMISE it: every personal detail is removed
     * and the account is switched off.
     */
    public void anonymise(int userId) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE users SET full_name = 'Deleted User', email = ?, phone = NULL, " +
                        "is_active = FALSE, consent_given = FALSE, reset_code_hash = NULL WHERE user_id = ?")) {
                    ps.setString(1, "deleted-" + userId + "@yep.invalid");
                    ps.setInt(2, userId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE participants SET district = NULL, bio = NULL, skills = NULL, " +
                        "portfolio_link = NULL, portfolio_public = FALSE WHERE user_id = ?")) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        }
    }

    // ----------------------------------------------------------------
    // Private helpers
    // ----------------------------------------------------------------

    /** Runs a SELECT with the given parameters and maps every row to a User. */
    private List<User> queryUsers(String sql, Object... params) throws SQLException {
        List<User> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRowToUser(rs));
            }
        }
        return list;
    }

    private void executeUpdate(String sql, Object... params) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            ps.executeUpdate();
        }
    }

    private List<Participant> toParticipants(List<User> users) {
        List<Participant> list = new ArrayList<>();
        for (User u : users) {
            if (u instanceof Participant p) list.add(p);
        }
        return list;
    }

    /** Maps a ResultSet row to the correct User subtype based on the role column. */
    private User mapRowToUser(ResultSet rs) throws SQLException {
        String role = rs.getString("role");
        return switch (role) {
            case "PARTICIPANT" -> mapRowToParticipant(rs);
            case "FACILITATOR" -> new Facilitator(
                rs.getInt("user_id"), rs.getString("full_name"),
                rs.getString("email"), rs.getString("phone"),
                rs.getString("password_hash"), rs.getString("country"),
                rs.getBoolean("is_active"), rs.getBoolean("consent_given"),
                rs.getInt("failed_logins"),
                rs.getTimestamp("created_at").toLocalDateTime(),
                rs.getString("organisation")
            );
            case "MENTOR" -> new Mentor(
                rs.getInt("user_id"), rs.getString("full_name"),
                rs.getString("email"), rs.getString("phone"),
                rs.getString("password_hash"), rs.getString("country"),
                rs.getBoolean("is_active"), rs.getBoolean("consent_given"),
                rs.getInt("failed_logins"),
                rs.getTimestamp("created_at").toLocalDateTime(),
                rs.getString("expertise"), rs.getInt("max_teams")
            );
            default -> new Admin(
                rs.getInt("user_id"), rs.getString("full_name"),
                rs.getString("email"), rs.getString("phone"),
                rs.getString("password_hash"), rs.getString("country"),
                rs.getBoolean("is_active"), rs.getBoolean("consent_given"),
                rs.getInt("failed_logins"),
                rs.getTimestamp("created_at").toLocalDateTime()
            );
        };
    }

    private Participant mapRowToParticipant(ResultSet rs) throws SQLException {
        Date dobDate = rs.getDate("date_of_birth");
        LocalDate dob = (dobDate != null) ? dobDate.toLocalDate() : LocalDate.of(2000, 1, 1);

        int teamIdInt = rs.getInt("team_id");
        Integer teamId = rs.wasNull() ? null : teamIdInt;

        Participant p = new Participant(
            rs.getInt("user_id"), rs.getString("full_name"),
            rs.getString("email"), rs.getString("phone"),
            rs.getString("password_hash"), rs.getString("country"),
            rs.getBoolean("is_active"), rs.getBoolean("consent_given"),
            rs.getInt("failed_logins"),
            rs.getTimestamp("created_at").toLocalDateTime(),
            rs.getInt("ve_level"), rs.getInt("points"), teamId,
            dob, rs.getString("gender"),
            rs.getString("district"), rs.getString("education_level"),
            rs.getBoolean("has_disability")
        );
        p.setBio(rs.getString("bio"));
        p.setSkills(rs.getString("skills"));
        p.setPortfolioLink(rs.getString("portfolio_link"));
        p.setPortfolioPublic(rs.getBoolean("portfolio_public"));
        return p;
    }
}
