package com.yep.servlet;

import com.yep.model.Admin;
import com.yep.model.User;
import com.yep.util.DatabaseConnection;
import com.yep.util.PasswordUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import com.yep.service.SampleContent;

import java.sql.*;
import java.util.List;

/**
 * SetupServlet — resets the database and loads demonstration data
 * (staff accounts, 8 participants from 5 EAC countries, 6 sessions with quizzes,
 * attendance and quiz scores) so the full YEP journey can be shown.
 *
 *   GET  /setup  → confirmation page
 *   POST /setup  → wipe all data and load the demo data
 *
 * SECURITY: because this deletes everything, it only works when opened on
 * the same computer as the server (localhost) or by a logged-in admin.
 */
@WebServlet("/setup")
public class SetupServlet extends BaseServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAllowed(request, response)) return;

        PrintWriter out = startPage(response);
        out.println("<h2>YEP System — Load Demo Data</h2>");
        out.println("<p>This will <strong>delete all existing data</strong> (users, sessions, scores, teams, "
                  + "projects and certificates) and load a fresh set of demonstration data.</p>");
        out.println("<form method='POST'><button class='btn'>Reset and load demo data</button></form>");
        out.println("<p style='margin-top:20px'><a href='" + request.getContextPath() + "/login'>Cancel</a></p>");
        endPage(out);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!isAllowed(request, response)) return;

        PrintWriter out = startPage(response);
        out.println("<h2>YEP System — Demo Data Setup</h2>");

        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);   // all or nothing
            try {
                loadDemoData(conn);
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                throw e;
            }

            // The session (if any) belonged to a user that no longer exists
            if (request.getSession(false) != null) request.getSession(false).invalidate();

            printSummary(out, request.getContextPath());

        } catch (Exception e) {
            log("Demo data setup failed", e);
            out.println("<div class='box err'><strong>Setup failed:</strong> "
                + com.yep.util.ValidationUtil.escapeHtml(e.getMessage())
                + "<br><br>Check that XAMPP MySQL is running and that you imported <code>schema.sql</code>.</div>");
        }
        endPage(out);
    }

    // ----------------------------------------------------------------

    private void loadDemoData(Connection conn) throws Exception {
        // ---- Clear existing data (child tables first because of foreign keys) ----
        String[] clear = {
            "DELETE FROM team_messages", "DELETE FROM opportunities",
            "DELETE FROM audit_log", "DELETE FROM certificates", "DELETE FROM assessments",
            "DELETE FROM attendance", "DELETE FROM quiz_questions", "DELETE FROM projects", "UPDATE participants SET team_id = NULL",
            "DELETE FROM teams", "DELETE FROM participants", "DELETE FROM facilitators",
            "DELETE FROM mentors", "DELETE FROM admins", "DELETE FROM activities", "DELETE FROM users"
        };
        for (String sql : clear) {
            try (PreparedStatement ps = conn.prepareStatement(sql)) { ps.executeUpdate(); }
        }

        // ---- Staff accounts ----
        int adminId = insertUser(conn, "YEP Admin", "admin@yep.org", "+256700000001",
                                 PasswordUtil.hash("Admin@1234"), "Uganda", "ADMIN");
        exec(conn, "INSERT INTO admins (user_id) VALUES (?)", adminId);

        int facilId = insertUser(conn, "Alice Kamau", "alice@yep.org", "+254700000002",
                                 PasswordUtil.hash("Facil@1234"), "Kenya", "FACILITATOR");
        exec(conn, "INSERT INTO facilitators (user_id, organisation) VALUES (?, ?)", facilId, "Nairobi Tech Hub");

        String mentorHash = PasswordUtil.hash("Mentor@1234");
        int mentor1 = insertUser(conn, "Brian Ochieng", "brian@yep.org", "+255700000003", mentorHash, "Tanzania", "MENTOR");
        exec(conn, "INSERT INTO mentors (user_id, expertise, max_teams) VALUES (?, ?, 3)",
             mentor1, "Digital Skills & Entrepreneurship");
        int mentor2 = insertUser(conn, "Esther Mukamana", "esther@yep.org", "+250700000004", mentorHash, "Rwanda", "MENTOR");
        exec(conn, "INSERT INTO mentors (user_id, expertise, max_teams) VALUES (?, ?, 3)",
             mentor2, "Agritech & Climate");

        // ---- Participants from 5 EAC countries (all use password Pass@1234) ----
        String pass = PasswordUtil.hash("Pass@1234");
        int p1 = insertParticipant(conn, "Amina Nakato",    "amina@yep.org",  pass, "Uganda",   "2001-03-15", "Female", "Kampala",       "+256701111111");
        int p2 = insertParticipant(conn, "David Omondi",    "david@yep.org",  pass, "Kenya",    "2000-07-22", "Male",   "Nairobi",       "+254722222222");
        int p3 = insertParticipant(conn, "Grace Uwimana",   "grace@yep.org",  pass, "Rwanda",   "2002-11-08", "Female", "Kigali",        "+250783333333");
        int p4 = insertParticipant(conn, "Samuel Mwenda",   "samuel@yep.org", pass, "Tanzania", "1999-05-30", "Male",   "Dar es Salaam", "+255714444444");
        int p5 = insertParticipant(conn, "Fatuma Hassan",   "fatuma@yep.org", pass, "Burundi",  "2001-09-12", "Female", "Bujumbura",     "+257725555555");
        int p6 = insertParticipant(conn, "Peter Lubega",    "peter@yep.org",  pass, "Uganda",   "2000-01-25", "Male",   "Entebbe",       "+256756666666");
        int p7 = insertParticipant(conn, "Halima Achieng",  "halima@yep.org", pass, "Kenya",    "2003-04-02", "Female", "Kisumu",        "+254787777777");
        int p8 = insertParticipant(conn, "Joseph Ssemakula","joseph@yep.org", pass, "Uganda",   "1998-12-19", "Male",   "Gulu",          "+256798888888");

        // ---- Level One sessions with learning notes and 5-question quizzes (see SampleContent) ----
        List<Integer> ids = SampleContent.insertAll(conn, facilId);
        int a1 = ids.get(0), a2 = ids.get(1), a3 = ids.get(2), a4 = ids.get(3), a5 = ids.get(4);
        // ids.get(5) is the upcoming session — nobody has completed it yet

        // ---- Attendance and scores: {participant, activity, score, type} ----
        // Quiz scores are multiples of 20 because each quiz has 5 questions.
        // Participation scores are given by the facilitator, so any value is possible.
        Object[][] results = {
            {p1, a1, 80, "quiz"}, {p1, a2, 80, "quiz"}, {p1, a3, 80, "quiz"}, {p1, a4, 76, "participation"},
            {p2, a1, 100, "quiz"}, {p2, a2, 80, "quiz"}, {p2, a3, 80, "quiz"}, {p2, a4, 80, "participation"}, {p2, a5, 80, "quiz"},
            {p3, a1, 60, "quiz"}, {p3, a2, 60, "quiz"}, {p3, a3, 80, "quiz"},
            {p4, a2, 60, "quiz"}, {p4, a3, 80, "quiz"}, {p4, a4, 68, "participation"}, {p4, a5, 80, "quiz"},
            {p5, a1, 60, "quiz"}, {p5, a3, 40, "quiz"}, {p5, a5, 60, "quiz"},          // avg 53: certificate yes, Level 2 no
            {p6, a1, 80, "quiz"}, {p6, a2, 60, "quiz"},                                // only 2 sessions — can finish one live
            {p7, a1, 80, "quiz"}, {p7, a3, 80, "quiz"}, {p7, a5, 80, "quiz"},
            {p8, a2, 60, "quiz"}, {p8, a4, 72, "participation"}, {p8, a5, 80, "quiz"},
        };
        String[] modes = {"video", "audio", "download"};
        int i = 0;
        for (Object[] r : results) {
            int participant = (int) r[0], activity = (int) r[1];
            exec(conn, "INSERT IGNORE INTO attendance (activity_id, user_id, mode) VALUES (?, ?, ?)",
                 activity, participant, modes[i++ % modes.length]);
            exec(conn, "UPDATE participants SET points = points + 10 WHERE user_id = ?", participant);
            exec(conn, "INSERT INTO assessments (participant_id, activity_id, score, type, comment, assessor_id) "
                     + "VALUES (?, ?, ?, ?, ?, ?)", participant, activity, r[2], r[3], "quiz".equals(r[3]) ? "Online quiz (auto-graded)" : "Recorded by facilitator.", facilId);
        }

        // ---- Skills portfolios that participants chose to share with employers (FR23) ----
        String portfolioSql = "UPDATE participants SET bio = ?, skills = ?, portfolio_link = ?, portfolio_public = ? WHERE user_id = ?";
        exec(conn, portfolioSql, "Business student from Kampala who builds simple websites for small shops.",
             "Canva, Google Sites, Excel, Customer service", "https://sites.google.com/view/amina-portfolio", true, p1);
        exec(conn, portfolioSql, "Computer science student interested in data and fighting misinformation online.",
             "Python basics, Data cleaning, Fact-checking, Public speaking", null, true, p2);
        exec(conn, portfolioSql, "Agriculture graduate using mobile tools to help farmers get better prices.",
             "Mobile money, Farmer training, Kinyarwanda/English translation", null, true, p3);
        exec(conn, portfolioSql, "Aspiring journalist.", "Writing, Social media", null, false, p7);   // private: not on the Talent page

        // ---- Partner opportunities (FR24) ----
        String oppSql = "INSERT INTO opportunities (title, organisation, opp_type, description, country, deadline, apply_link, posted_by) "
                      + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        exec(conn, oppSql, "Junior Data Assistant Internship", "Kampala Digital Hub", "internship",
             "A 3-month paid internship cleaning and visualising data for local NGOs. Basic spreadsheet skills required; YEP Level One certificate preferred.",
             "Uganda", Date.valueOf(java.time.LocalDate.now().plusDays(60)), "https://example.org/apply/data-intern", adminId);
        exec(conn, oppSql, "Climate Solutions Challenge 2027", "Green Futures East Africa", "challenge",
             "Teams propose a low-cost digital idea that helps farmers adapt to climate change. The best 3 teams receive seed funding and mentoring.",
             null, Date.valueOf(java.time.LocalDate.now().plusDays(90)), "https://example.org/climate-challenge", adminId);
        exec(conn, oppSql, "Social Media Officer (Remote)", "Youth Voices Network", "internship",
             "Help run social media campaigns for youth programmes. Must understand online safety and how to spot misinformation.",
             "Kenya", Date.valueOf(java.time.LocalDate.now().plusDays(30)), null, adminId);

        exec(conn, "INSERT INTO audit_log (user_id, action, detail) VALUES (?, 'setup', 'Demo data loaded')", adminId);
    }

    private void printSummary(PrintWriter out, String ctx) {
        out.println("<div class='box ok'><h3>✓ Demo data loaded</h3>");
        out.println("<h4>Staff accounts</h4><table>");
        out.println("<tr><th>Role</th><th>Email</th><th>Password</th></tr>");
        out.println("<tr><td>Admin</td><td>admin@yep.org</td><td>Admin@1234</td></tr>");
        out.println("<tr><td>Facilitator</td><td>alice@yep.org</td><td>Facil@1234</td></tr>");
        out.println("<tr><td>Mentor</td><td>brian@yep.org</td><td>Mentor@1234</td></tr>");
        out.println("<tr><td>Mentor</td><td>esther@yep.org</td><td>Mentor@1234</td></tr>");
        out.println("</table>");
        out.println("<h4>Participants (password Pass@1234)</h4><table>");
        out.println("<tr><th>Name</th><th>Email</th><th>Country</th><th>Sessions</th><th>Average</th><th>Level 2 eligible?</th></tr>");
        String[][] rows = {
            {"Amina Nakato", "amina@yep.org", "Uganda", "4", "79%", "Yes"},
            {"David Omondi", "david@yep.org", "Kenya", "5", "84%", "Yes"},
            {"Grace Uwimana", "grace@yep.org", "Rwanda", "3", "67%", "Yes"},
            {"Samuel Mwenda", "samuel@yep.org", "Tanzania", "4", "72%", "Yes"},
            {"Fatuma Hassan", "fatuma@yep.org", "Burundi", "3", "53%", "No (average below 60%)"},
            {"Peter Lubega", "peter@yep.org", "Uganda", "2", "70%", "No — complete one more session"},
            {"Halima Achieng", "halima@yep.org", "Kenya", "3", "80%", "Yes"},
            {"Joseph Ssemakula", "joseph@yep.org", "Uganda", "3", "71%", "Yes"},
        };
        for (String[] r : rows) {
            out.println("<tr><td>" + String.join("</td><td>", r) + "</td></tr>");
        }
        out.println("</table>");
        out.println("<p><strong>Try the learning journey:</strong> sign in as <code>peter@yep.org</code>, open a "
                  + "session he has not done (e.g. <em>Spotting Fake News</em>), read the notes, join and take the quiz. "
                  + "With 3 sessions and a 60%+ average he appears on the admin's Promote page. Or register a brand-new "
                  + "participant and complete 3 sessions from scratch.</p>");
        out.println("<p>Suggested demo: sign in as admin → Promote (6 eligible) → Teams → Form teams → "
                  + "assign mentors → sign in as a participant → write and submit the project → "
                  + "sign in as the mentor → approve → admin → Certificates → issue → Verify.</p>");
        out.println("<p><strong>New features:</strong> once teams are formed, open <em>My Team</em> to use the team chat "
                  + "(flag a message, then review it on the admin dashboard). Amina, David and Grace have public portfolios on "
                  + "the <em>Talent</em> page, partners' internships are on <em>Opportunities</em>, and "
                  + "<em>Forgot password?</em> on the login page shows the one-time code in demo mode.</p>");
        out.println("</div><p><a class='btn' href='" + ctx + "/login'>Go to login →</a></p>");
    }

    /** Only allow the reset from the server computer itself or for a logged-in admin. */
    private boolean isAllowed(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String ip = request.getRemoteAddr();
        boolean local = "127.0.0.1".equals(ip) || "0:0:0:0:0:0:0:1".equals(ip) || "::1".equals(ip);
        User user = currentUser(request);
        if (local || user instanceof Admin) return true;

        response.sendError(HttpServletResponse.SC_FORBIDDEN,
            "Demo setup can only be run on the server computer or by an administrator.");
        return false;
    }

    private PrintWriter startPage(HttpServletResponse response) throws IOException {
        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println("<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'>"
            + "<meta name='viewport' content='width=device-width, initial-scale=1.0'><title>Demo Setup — YEP</title>"
            + "<style>body{font-family:system-ui,sans-serif;padding:30px 16px;max-width:860px;margin:auto;color:#111827}"
            + "table{border-collapse:collapse;margin-bottom:16px;width:100%}th,td{border:1px solid #d1d5db;padding:6px 10px;text-align:left;font-size:.9rem}"
            + "th{background:#f3f4f6}.box{padding:20px;border-radius:8px;margin:16px 0}.ok{background:#ecfdf5;border:2px solid #16a34a}"
            + ".err{background:#fef2f2;border:2px solid #dc2626}.btn{display:inline-block;background:#15803d;color:#fff;border:0;"
            + "padding:12px 22px;border-radius:6px;font-weight:600;text-decoration:none;cursor:pointer;font-size:1rem}</style></head><body>");
        return out;
    }

    private void endPage(PrintWriter out) {
        out.println("</body></html>");
    }

    // ---- Small JDBC helpers ----

    private void exec(Connection conn, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            ps.executeUpdate();
        }
    }

    private int insertUser(Connection conn, String name, String email, String phone,
                           String hash, String country, String role) throws SQLException {
        String sql = "INSERT INTO users (full_name, email, phone, password_hash, country, role, is_active, consent_given) "
                   + "VALUES (?, ?, ?, ?, ?, ?, TRUE, TRUE)";
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name);    ps.setString(2, email);
            ps.setString(3, phone);   ps.setString(4, hash);
            ps.setString(5, country); ps.setString(6, role);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    private int insertParticipant(Connection conn, String name, String email, String hash, String country,
                                  String dob, String gender, String district, String phone) throws SQLException {
        int userId = insertUser(conn, name, email, phone, hash, country, "PARTICIPANT");
        exec(conn, "INSERT INTO participants (user_id, ve_level, points, date_of_birth, gender, district, education_level) "
                 + "VALUES (?, 1, 0, ?, ?, ?, ?)", userId, Date.valueOf(dob), gender, district, "Bachelor's Degree");
        return userId;
    }
}
