package com.yep.servlet;

import com.yep.dao.*;
import com.yep.model.*;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * ProjectServlet — Impact Project creation, submission and mentor review (FR15, FR16).
 *
 *   GET  /project                → participant: their team's project; mentor: projects to review
 *   POST /project action=save    → create or update the draft (participant)
 *   POST /project action=submit  → submit for review (participant)
 *   POST /project action=review  → approve or request revision (mentor of that team only)
 *
 * PROJECT LIFECYCLE:
 *   draft → submitted → approved
 *                     ↘ revision_requested → submitted → ...
 */
@WebServlet("/project")
public class ProjectServlet extends BaseServlet {

    private final ProjectDAO  projectDAO = new ProjectDAO();
    private final TeamDAO     teamDAO    = new TeamDAO();
    private final UserDAO     userDAO    = new UserDAO();
    private final AuditLogDAO auditLog   = new AuditLogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = currentUser(request);
        if (user == null) { redirect(request, response, "/login"); return; }

        try {
            if (user instanceof Participant participant) {
                if (participant.getTeamId() == null) {
                    flash(request, "info", "You need to be in a Level Two team before starting an Impact Project.");
                    redirect(request, response, participant.getDashboardMenu());
                    return;
                }
                request.setAttribute("project", projectDAO.findByTeam(participant.getTeamId()));
                request.setAttribute("team",    teamDAO.findById(participant.getTeamId()));
                forward(request, response, "/participant/project.jsp");

            } else if (user instanceof Mentor mentor) {
                List<Team> teams = teamDAO.findByMentor(mentor.getUserId());
                Map<Integer, Project> projectMap = new HashMap<>();
                Map<Integer, List<Participant>> membersMap = new HashMap<>();
                for (Team t : teams) {
                    Project p = projectDAO.findByTeam(t.getTeamId());
                    if (p != null) projectMap.put(t.getTeamId(), p);
                    membersMap.put(t.getTeamId(), userDAO.findByTeam(t.getTeamId()));
                }
                request.setAttribute("teams",      teams);
                request.setAttribute("projectMap", projectMap);
                request.setAttribute("membersMap", membersMap);
                forward(request, response, "/mentor/projects.jsp");

            } else {
                redirect(request, response, user.getDashboardMenu());
            }
        } catch (Exception e) {
            showError(request, response, "Could not load the project page.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = param(request, "action");
        try {
            switch (action) {
                case "save" -> {
                    Participant p = requireRole(request, response, Participant.class);
                    if (p != null) saveProject(request, response, p);
                }
                case "submit" -> {
                    Participant p = requireRole(request, response, Participant.class);
                    if (p != null) submitProject(request, response, p);
                }
                case "review" -> {
                    Mentor m = requireRole(request, response, Mentor.class);
                    if (m != null) reviewProject(request, response, m);
                }
                default -> redirect(request, response, "/project");
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
            redirect(request, response, "/project");
        } catch (Exception e) {
            showError(request, response, "That project action could not be completed.", e);
        }
    }

    /** FR15 — creates the team's project or updates the draft. */
    private void saveProject(HttpServletRequest request, HttpServletResponse response,
                             Participant participant) throws Exception {
        Integer teamId = participant.getTeamId();
        if (teamId == null) throw new YEPException("You are not in a team yet.");

        String title            = param(request, "title");
        String problemStatement = param(request, "problemStatement");
        String aiDeclaration    = param(request, "aiUseDeclaration");

        if (title.length() < 5 || title.length() > 200)
            throw new YEPException("Project title must be 5–200 characters.");
        if (problemStatement.length() < 20)
            throw new YEPException("Please describe the problem in at least 20 characters.");
        if (aiDeclaration.length() < 5)
            throw new YEPException("The AI-use declaration is required. If you did not use AI, write \"No AI tools were used\".");

        Project existing = projectDAO.findByTeam(teamId);
        if (existing == null) {
            projectDAO.create(new Project(teamId, title, problemStatement, aiDeclaration));
            auditLog.log(participant.getUserId(), "create_project", title);
        } else if (existing.isEditable()) {
            existing.setTitle(title);
            existing.setProblemStatement(problemStatement);
            existing.setAiUseDeclaration(aiDeclaration);
            projectDAO.update(existing);
        } else {
            throw new YEPException("The project can't be edited while it is " + existing.getStatusLabel().toLowerCase() + ".");
        }

        flash(request, "success", "Project saved as a draft.");
        redirect(request, response, "/project");
    }

    /** FR15 — sends the project to the team's mentor. */
    private void submitProject(HttpServletRequest request, HttpServletResponse response,
                               Participant participant) throws Exception {
        if (participant.getTeamId() == null) throw new YEPException("You are not in a team yet.");

        Project project = projectDAO.findByTeam(participant.getTeamId());
        if (project == null) throw new YEPException("Save your project before submitting it.");
        if (!project.isEditable()) throw new YEPException("This project has already been submitted.");

        Team team = teamDAO.findById(participant.getTeamId());
        if (team.getMentorId() == null)
            throw new YEPException("Your team does not have a mentor yet. Please wait for the admin to assign one.");

        projectDAO.submit(project.getProjectId());
        auditLog.log(participant.getUserId(), "submit_project", project.getTitle());

        User mentor = userDAO.findById(team.getMentorId());
        if (mentor != null) {
            mentor.sendNotification("Project submitted for review",
                team.getName() + " has submitted \"" + project.getTitle() + "\".");
        }

        flash(request, "success", "Project submitted! Your mentor will review it.");
        redirect(request, response, "/project");
    }

    /** FR16 — the team's own mentor approves the project or asks for changes. */
    private void reviewProject(HttpServletRequest request, HttpServletResponse response,
                               Mentor mentor) throws Exception {
        Project project = projectDAO.findById(intParam(request, "projectId"));
        if (project == null) throw new YEPException("Project not found.");

        Team team = teamDAO.findById(project.getTeamId());
        if (team == null || !Integer.valueOf(mentor.getUserId()).equals(team.getMentorId()))
            throw new YEPException("You can only review projects of teams assigned to you.");
        if (!Project.STATUS_SUBMITTED.equals(project.getStatus()))
            throw new YEPException("Only submitted projects can be reviewed.");

        String decision = param(request, "decision");
        String feedback = param(request, "feedback");
        if (!Project.STATUS_APPROVED.equals(decision) && !Project.STATUS_REVISION_REQUESTED.equals(decision))
            throw new YEPException("Please choose Approve or Request Revision.");
        if (Project.STATUS_REVISION_REQUESTED.equals(decision) && feedback.length() < 5)
            throw new YEPException("Please tell the team what to change when requesting a revision.");

        projectDAO.review(project.getProjectId(), decision, feedback.isEmpty() ? null : feedback);
        auditLog.log(mentor.getUserId(), "review_project", project.getTitle() + " → " + decision);

        String outcome = Project.STATUS_APPROVED.equals(decision) ? "approved" : "returned for revision";
        for (Participant member : userDAO.findByTeam(team.getTeamId())) {
            member.sendNotification("Project review", "Your project \"" + project.getTitle() + "\" was " + outcome + ".");
        }

        flash(request, "success", "\"" + project.getTitle() + "\" " + outcome + ".");
        redirect(request, response, "/project");
    }
}
