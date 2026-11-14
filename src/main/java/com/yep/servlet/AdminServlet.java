package com.yep.servlet;

import com.yep.dao.*;
import com.yep.model.*;
import com.yep.service.CertificateService;
import com.yep.service.TeamService;
import com.yep.util.PasswordUtil;
import com.yep.util.ValidationUtil;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.*;

/**
 * AdminServlet — YEP Secretariat management (FR12, FR13, FR14, FR19, FR21, FR22).
 *
 * Only users with the ADMIN role can use it (checked by requireRole()).
 *
 *   GET  /admin                    → dashboard (figures, to-do list, recent activity)
 *   GET  /admin?page=users         → user management (FR22)
 *   GET  /admin?page=promote       → participants eligible for Level Two (FR12)
 *   GET  /admin?page=teams         → team formation and mentor assignment (FR13, FR14)
 *   GET  /admin?page=certificates  → issue certificates (FR19, UC-12)
 *   GET  /admin?page=reports       → programme reports (FR21)
 *
 *   POST actions: toggleActive, unlock, createStaff, promoteOne, promoteAll,
 *                 formTeams, assignMentor, issueCert,
 *                 keepMessage, deleteMessage (review of flagged team messages, FR17)
 */
@WebServlet("/admin")
public class AdminServlet extends BaseServlet {

    private final UserDAO        userDAO        = new UserDAO();
    private final TeamDAO        teamDAO        = new TeamDAO();
    private final ActivityDAO    activityDAO    = new ActivityDAO();
    private final AssessmentDAO  assessmentDAO  = new AssessmentDAO();
    private final CertificateDAO certDAO        = new CertificateDAO();
    private final ReportDAO      reportDAO      = new ReportDAO();
    private final AuditLogDAO    auditLog       = new AuditLogDAO();
    private final MessageDAO     messageDAO     = new MessageDAO();

    private final CertificateService certificateService = new CertificateService();
    private final TeamService        teamService        = new TeamService();

    // ================================================================
    // GET — pages
    // ================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Admin admin = requireRole(request, response, Admin.class);
        if (admin == null) return;

        String page = param(request, "page");
        try {
            switch (page) {
                case "users"        -> showUsers(request, response);
                case "promote"      -> showPromote(request, response);
                case "teams"        -> showTeams(request, response);
                case "certificates" -> showCertificates(request, response);
                case "reports"      -> showReports(request, response);
                default             -> showDashboard(request, response);
            }
        } catch (Exception e) {
            showError(request, response, "Could not load the admin page.", e);
        }
    }

    private void showDashboard(HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("participants", reportDAO.totalParticipants());
        request.setAttribute("staff",        reportDAO.totalStaff());
        request.setAttribute("sessions",     reportDAO.sessionsHeld());
        request.setAttribute("teams",        reportDAO.teams());
        request.setAttribute("certificates", reportDAO.certificatesIssued());

        // "To do" counts so the admin knows what needs attention
        request.setAttribute("eligibleCount", userDAO.findEligibleForPromotion().size());
        request.setAttribute("waitingCount",  userDAO.findLevel2WithoutTeam().size());
        request.setAttribute("noMentorCount", teamDAO.findAll().stream().filter(t -> t.getMentorId() == null).count());

        request.setAttribute("flagged", messageDAO.findFlagged());
        request.setAttribute("recent", auditLog.findRecent(10));
        forward(request, response, "/admin/dashboard.jsp");
    }

    private void showUsers(HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("users", userDAO.findAll());
        forward(request, response, "/admin/users.jsp");
    }

    private void showPromote(HttpServletRequest request, HttpServletResponse response) throws Exception {
        List<ParticipantProgress> rows = new ArrayList<>();
        for (Participant p : userDAO.findEligibleForPromotion()) {
            rows.add(new ParticipantProgress(p, activityDAO.countAttendance(p.getUserId()),
                     assessmentDAO.getAverageScore(p.getUserId()), null, null));
        }
        request.setAttribute("eligible", rows);
        forward(request, response, "/admin/promote.jsp");
    }

    private void showTeams(HttpServletRequest request, HttpServletResponse response) throws Exception {
        List<Team> teams = teamDAO.findAll();
        List<Mentor> mentors = userDAO.findMentors();

        Map<Integer, List<Participant>> membersMap = new HashMap<>();
        for (Team t : teams) membersMap.put(t.getTeamId(), userDAO.findByTeam(t.getTeamId()));

        Map<Integer, String>  mentorNames = new HashMap<>();
        Map<Integer, Integer> mentorLoad  = new HashMap<>();
        for (Mentor m : mentors) {
            mentorNames.put(m.getUserId(), m.getFullName());
            mentorLoad.put(m.getUserId(), teamDAO.countTeamsForMentor(m.getUserId()));
        }

        request.setAttribute("teams",       teams);
        request.setAttribute("mentors",     mentors);
        request.setAttribute("membersMap",  membersMap);
        request.setAttribute("mentorNames", mentorNames);
        request.setAttribute("mentorLoad",  mentorLoad);
        request.setAttribute("unassigned",  userDAO.findLevel2WithoutTeam());
        forward(request, response, "/admin/teams.jsp");
    }

    private void showCertificates(HttpServletRequest request, HttpServletResponse response) throws Exception {
        List<ParticipantProgress> rows = new ArrayList<>();
        for (Participant p : userDAO.findAllParticipants()) {
            rows.add(new ParticipantProgress(p,
                activityDAO.countAttendance(p.getUserId()),
                assessmentDAO.getAverageScore(p.getUserId()),
                certificateService.checkEligibility(p, Certificate.TYPE_LEVEL1),
                certificateService.checkEligibility(p, Certificate.TYPE_LEVEL2)));
        }

        Map<Integer, String> names = new HashMap<>();
        for (ParticipantProgress row : rows) names.put(row.getParticipant().getUserId(), row.getParticipant().getFullName());

        request.setAttribute("rows",   rows);
        request.setAttribute("issued", certDAO.findAll());
        request.setAttribute("names",  names);
        forward(request, response, "/admin/certificates.jsp");
    }

    private void showReports(HttpServletRequest request, HttpServletResponse response) throws Exception {
        request.setAttribute("totalParticipants", reportDAO.totalParticipants());
        request.setAttribute("sessionsHeld",      reportDAO.sessionsHeld());
        request.setAttribute("attendance",        reportDAO.attendanceRecords());
        request.setAttribute("certificates",      reportDAO.certificatesIssued());
        request.setAttribute("averageScore",      reportDAO.overallAverageScore());
        request.setAttribute("byCountry",         reportDAO.participantsByCountry());
        request.setAttribute("byGender",          reportDAO.participantsByGender());
        request.setAttribute("byLevel",           reportDAO.participantsByLevel());
        request.setAttribute("byMode",            reportDAO.attendanceByMode());
        request.setAttribute("certsByType",       reportDAO.certificatesByType());
        request.setAttribute("projectsByStatus",  reportDAO.projectsByStatus());
        forward(request, response, "/admin/reports.jsp");
    }

    // ================================================================
    // POST — actions
    // ================================================================

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Admin admin = requireRole(request, response, Admin.class);
        if (admin == null) return;

        String action = param(request, "action");
        String back   = "/admin";
        try {
            switch (action) {
                case "toggleActive" -> { back = "/admin?page=users";        toggleActive(request, admin); }
                case "unlock"       -> { back = "/admin?page=users";        unlock(request, admin); }
                case "createStaff"  -> { back = "/admin?page=users";        createStaff(request, admin); }
                case "promoteOne"   -> { back = "/admin?page=promote";      promoteOne(request, admin); }
                case "promoteAll"   -> { back = "/admin?page=promote";      promoteAll(request, admin); }
                case "formTeams"    -> { back = "/admin?page=teams";        formTeams(request, admin); }
                case "assignMentor" -> { back = "/admin?page=teams";        assignMentor(request, admin); }
                case "issueCert"    -> { back = "/admin?page=certificates"; issueCert(request, admin); }
                case "keepMessage"  -> reviewMessage(request, admin, false);
                case "deleteMessage"-> reviewMessage(request, admin, true);
                default -> { }
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        } catch (Exception e) {
            log("Admin action failed: " + action, e);
            flash(request, "error", "The action could not be completed because of a system problem.");
        }
        redirect(request, response, back);
    }

    /** FR22 — activate or deactivate an account. */
    private void toggleActive(HttpServletRequest request, Admin admin) throws Exception {
        int targetId   = intParam(request, "userId");
        boolean active = "true".equals(param(request, "active"));
        if (targetId == admin.getUserId())
            throw new YEPException("You cannot deactivate your own account.");

        User target = requireUser(targetId);
        userDAO.setActiveStatus(targetId, active);
        auditLog.log(admin.getUserId(), active ? "activate_user" : "deactivate_user", target.getFullName());
        flash(request, "success", target.getFullName() + (active ? " has been activated." : " has been deactivated."));
    }

    /** FR04 — clears the failed-login counter so a locked user can sign in again. */
    private void unlock(HttpServletRequest request, Admin admin) throws Exception {
        User target = requireUser(intParam(request, "userId"));
        userDAO.updateFailedLogins(target.getUserId(), 0);
        auditLog.log(admin.getUserId(), "unlock_account", target.getFullName());
        flash(request, "success", target.getFullName() + "'s account has been unlocked.");
    }

    /** FR22 — creates a facilitator or mentor account. */
    private void createStaff(HttpServletRequest request, Admin admin) throws Exception {
        String role     = param(request, "role");
        String name     = param(request, "fullName");
        String email    = ValidationUtil.normaliseEmail(request.getParameter("email"));
        String phone    = param(request, "phone");
        String country  = param(request, "country");
        String extra    = param(request, "extra");      // organisation (facilitator) or expertise (mentor)
        String password = request.getParameter("password");

        if (name.length() < 3)                       throw new YEPException("Please enter the staff member's full name.");
        if (!ValidationUtil.isValidEmail(email))     throw new YEPException("Please enter a valid email address.");
        if (!ValidationUtil.isValidPhone(phone))     throw new YEPException("Phone number should be 9–15 digits.");
        if (!ValidationUtil.isEacCountry(country))   throw new YEPException("Please choose a country.");
        if (!PasswordUtil.isStrongEnough(password))  throw new YEPException("Temporary password must be 8+ characters with letters and numbers.");
        if (userDAO.emailExists(email))              throw new YEPException("An account with this email already exists.");

        String hash = PasswordUtil.hash(password);
        String phoneOrNull = phone.isEmpty() ? null : phone;
        String extraOrNull = extra.isEmpty() ? null : extra;

        // Polymorphism: both subclasses are handled through the User type
        User staff = switch (role) {
            case "FACILITATOR" -> new Facilitator(name, email, phoneOrNull, hash, country, extraOrNull);
            case "MENTOR"      -> new Mentor(name, email, phoneOrNull, hash, country, extraOrNull);
            default            -> throw new YEPException("Please choose Facilitator or Mentor.");
        };

        if (staff instanceof Facilitator f) userDAO.createFacilitator(f);
        else                                userDAO.createMentor((Mentor) staff);

        auditLog.log(admin.getUserId(), "create_staff", staff.getRole() + ": " + name);
        flash(request, "success", name + " can now sign in as a " + staff.getRole().toLowerCase() + ".");
    }

    /** FR12 — promotes one participant after re-checking the rule. */
    private void promoteOne(HttpServletRequest request, Admin admin) throws Exception {
        int targetId = intParam(request, "userId");
        Participant p = userDAO.findEligibleForPromotion().stream()
            .filter(e -> e.getUserId() == targetId)
            .findFirst()
            .orElseThrow(() -> new YEPException("That participant does not meet the Level Two requirements."));
        promote(p, admin);
        flash(request, "success", p.getFullName() + " has been promoted to Level Two.");
    }

    /** FR12 — promotes everyone who currently meets the rule. */
    private void promoteAll(HttpServletRequest request, Admin admin) throws Exception {
        List<Participant> eligible = userDAO.findEligibleForPromotion();
        if (eligible.isEmpty()) throw new YEPException("No participants are currently eligible.");
        for (Participant p : eligible) promote(p, admin);
        flash(request, "success", eligible.size() + " participant(s) promoted to Level Two.");
    }

    private void promote(Participant p, Admin admin) throws Exception {
        userDAO.promoteToLevelTwo(p.getUserId());
        p.promoteToLevelTwo();
        auditLog.log(admin.getUserId(), "promote_level2", p.getFullName());
        p.sendNotification("Selected for Level Two",
            "Congratulations! You have been selected for YEP Level Two.");
    }

    /** FR13 — automatic cross-country team formation (see TeamService). */
    private void formTeams(HttpServletRequest request, Admin admin) throws Exception {
        List<Team> created = teamService.formTeams(param(request, "focusArea"), admin.getUserId());
        StringBuilder names = new StringBuilder();
        for (Team t : created) {
            if (names.length() > 0) names.append(", ");
            names.append(t.getName()).append(" [").append(t.getMemberCount()).append("]");
        }
        flash(request, "success", created.size() + " team(s) formed: " + names + ".");
    }

    /** FR14 — assigns a mentor, limiting each mentor to max_teams (3). */
    private void assignMentor(HttpServletRequest request, Admin admin) throws Exception {
        Team team = teamDAO.findById(intParam(request, "teamId"));
        if (team == null) throw new YEPException("Please choose a team.");

        User user = userDAO.findById(intParam(request, "mentorId"));
        if (!(user instanceof Mentor mentor) || !mentor.isActive())
            throw new YEPException("Please choose an active mentor.");

        if (Integer.valueOf(mentor.getUserId()).equals(team.getMentorId()))
            throw new YEPException(mentor.getFullName() + " is already the mentor of " + team.getName() + ".");

        if (teamDAO.countTeamsForMentor(mentor.getUserId()) >= mentor.getMaxTeams())
            throw new YEPException(mentor.getFullName() + " already mentors " + mentor.getMaxTeams()
                + " teams, which is the maximum.");

        teamDAO.assignMentor(team.getTeamId(), mentor.getUserId());
        auditLog.log(admin.getUserId(), "assign_mentor", team.getName() + " → " + mentor.getFullName());

        mentor.sendNotification("New team assigned", "You are now the mentor of " + team.getName() + ".");
        for (Participant member : userDAO.findByTeam(team.getTeamId())) {
            member.sendNotification("Mentor assigned",
                "Your mentor is " + mentor.getFullName() + " (" + mentor.getExpertise() + ").");
        }
        flash(request, "success", mentor.getFullName() + " is now mentoring " + team.getName() + ".");
    }

    /** FR19 — issues a certificate if the participant is eligible (see CertificateService). */
    private void issueCert(HttpServletRequest request, Admin admin) throws Exception {
        Certificate cert = certificateService.issue(intParam(request, "participantId"),
                                                    param(request, "certType"), admin.getUserId());
        flash(request, "success", cert.getTypeLabel() + " certificate issued. Code: " + cert.getVerificationCode());
    }

    /** FR17 — the admin decides what happens to a flagged team message. */
    private void reviewMessage(HttpServletRequest request, Admin admin, boolean remove) throws Exception {
        Message msg = messageDAO.findById(intParam(request, "messageId"));
        if (msg == null) throw new YEPException("Message not found.");
        if (remove) {
            messageDAO.delete(msg.getMessageId());
            auditLog.log(admin.getUserId(), "delete_message", msg.getTeamName() + ": message by " + msg.getSenderName());
            flash(request, "success", "The message was removed from " + msg.getTeamName() + ".");
        } else {
            messageDAO.clearFlag(msg.getMessageId());
            auditLog.log(admin.getUserId(), "keep_message", msg.getTeamName() + ": message by " + msg.getSenderName());
            flash(request, "success", "The flag was cleared and the message stays visible.");
        }
    }

    private User requireUser(int userId) throws Exception {
        User user = userDAO.findById(userId);
        if (user == null) throw new YEPException("User not found.");
        return user;
    }
}
