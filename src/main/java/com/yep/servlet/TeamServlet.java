package com.yep.servlet;

import com.yep.dao.AuditLogDAO;
import com.yep.dao.MessageDAO;
import com.yep.dao.ProjectDAO;
import com.yep.dao.TeamDAO;
import com.yep.dao.UserDAO;
import com.yep.model.*;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * TeamServlet — the team workspace: members, mentor, project summary and
 * the team discussion board (FR13, FR14, FR17).
 *
 *   GET  /team             → a participant sees their own team
 *   GET  /team?teamId=X    → a mentor sees one of their teams; an admin sees any team
 *   POST /team  action=send  → post a message to the team discussion
 *   POST /team  action=flag  → flag a message as inappropriate or misleading
 */
@WebServlet("/team")
public class TeamServlet extends BaseServlet {

    private final TeamDAO    teamDAO    = new TeamDAO();
    private final ProjectDAO projectDAO = new ProjectDAO();
    private final UserDAO    userDAO    = new UserDAO();
    private final MessageDAO messageDAO = new MessageDAO();
    private final AuditLogDAO auditLog  = new AuditLogDAO();

    /** How many recent messages the discussion board shows. */
    private static final int MESSAGES_SHOWN = 50;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = currentUser(request);
        if (user == null) { redirect(request, response, "/login"); return; }

        try {
            Team team = findTeamFor(user, request);
            if (team == null) {
                flash(request, "info", "You are not in a team yet. Teams are formed after promotion to Level Two.");
                redirect(request, response, user.getDashboardMenu());
                return;
            }

            request.setAttribute("team",    team);
            request.setAttribute("members", userDAO.findByTeam(team.getTeamId()));
            request.setAttribute("project", projectDAO.findByTeam(team.getTeamId()));
            request.setAttribute("mentor",  team.getMentorId() != null ? userDAO.findById(team.getMentorId()) : null);
            request.setAttribute("messages", messageDAO.findByTeam(team.getTeamId(), MESSAGES_SHOWN));
            forward(request, response, "/participant/team.jsp");

        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
            redirect(request, response, user.getDashboardMenu());
        } catch (Exception e) {
            showError(request, response, "Could not load the team page.", e);
        }
    }

    // ================================================================
    // POST — team discussion (FR17)
    // ================================================================

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = currentUser(request);
        if (user == null) { redirect(request, response, "/login"); return; }

        String back = user instanceof Participant ? "/team" : "/team?teamId=" + param(request, "teamId");
        try {
            Team team = findTeamFor(user, request);
            if (team == null) throw new YEPException("You are not in a team yet.");
            back = user instanceof Participant ? "/team" : "/team?teamId=" + team.getTeamId();

            switch (param(request, "action")) {
                case "send" -> {
                    String body = param(request, "body");
                    if (body.isEmpty())                      throw new YEPException("Please type a message first.");
                    if (body.length() > Message.MAX_LENGTH)  throw new YEPException("Messages can be at most " + Message.MAX_LENGTH + " characters.");
                    messageDAO.send(team.getTeamId(), user.getUserId(), body);
                }
                case "flag" -> {
                    Message msg = messageDAO.findById(intParam(request, "messageId"));
                    // A user can only flag messages that belong to a team they can see
                    if (msg == null || msg.getTeamId() != team.getTeamId()) throw new YEPException("Message not found.");
                    if (msg.isFrom(user)) throw new YEPException("You cannot flag your own message.");
                    messageDAO.flag(msg.getMessageId(), user.getUserId());
                    auditLog.log(user.getUserId(), "flag_message", team.getName() + ": message #" + msg.getMessageId());
                    flash(request, "info", "Thank you. The message was flagged and an administrator will review it.");
                }
                default -> { }
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        } catch (Exception e) {
            log("Team discussion action failed", e);
            flash(request, "error", "Your message could not be saved because of a system problem.");
        }
        redirect(request, response, back + "#chat");
    }

    /** Works out which team this user is allowed to see. */
    private Team findTeamFor(User user, HttpServletRequest request) throws Exception {
        if (user instanceof Participant p) {
            return p.getTeamId() == null ? null : teamDAO.findById(p.getTeamId());
        }

        Team team = teamDAO.findById(intParam(request, "teamId"));
        if (team == null) throw new YEPException("Team not found.");

        if (user instanceof Admin) return team;
        if (user instanceof Mentor && Integer.valueOf(user.getUserId()).equals(team.getMentorId())) return team;

        throw new YEPException("You can only view teams assigned to you.");
    }
}
