<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    Mentor project review (FR16). ProjectServlet supplies the mentor's teams,
    a team_id -> Project map and a team_id -> members map.
--%>
<%
    List<Team> teams = (List<Team>) request.getAttribute("teams");
    Map<Integer, Project> projectMap = (Map<Integer, Project>) request.getAttribute("projectMap");
    Map<Integer, List<Participant>> membersMap = (Map<Integer, List<Participant>>) request.getAttribute("membersMap");
    if (teams == null)      teams      = new ArrayList<>();
    if (projectMap == null) projectMap = new HashMap<>();
    if (membersMap == null) membersMap = new HashMap<>();
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Review Projects — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Team Projects</h1>
    <p>Review your teams' Impact Projects. Approve them, or request a revision with clear feedback.</p>
</div></div>
<main class="main-content" id="main">
    <% if (teams.isEmpty()) { %>
        <div class="card empty-state">
            <div style="display:flex;justify-content:center;margin-bottom:10px;"><iconify-icon icon="tabler:users-minus" width="44" height="44" style="color:var(--text-muted);"></iconify-icon></div>
            <p>No teams have been assigned to you yet.</p>
        </div>
    <% } else { for (Team team : teams) {
        Project project = projectMap.get(team.getTeamId());
        List<Participant> members = membersMap.getOrDefault(team.getTeamId(), Collections.emptyList()); %>
        <section class="card" aria-labelledby="team<%= team.getTeamId() %>">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px;margin-bottom:12px;">
                <div>
                    <h2 id="team<%= team.getTeamId() %>" style="font-size:1rem;display:inline;"><%= esc(team.getName()) %></h2>
                    <span class="badge badge-blue" style="margin-left:8px;"><%= esc(team.getFocusLabel()) %></span>
                </div>
                <a href="<%= ctx %>/team?teamId=<%= team.getTeamId() %>" class="btn btn-outline btn-sm">
                    <iconify-icon icon="tabler:users-group" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> View Team
                </a>
            </div>
            <div class="pill-list" style="margin-bottom:12px;">
                <% for (Participant m : members) { %>
                    <span class="pill"><%= esc(m.getFullName()) %> &middot; <%= esc(m.getCountry()) %></span>
                <% } %>
            </div>

            <% if (project == null) { %>
                <p class="muted">This team has not started a project yet.</p>
            <% } else { %>
                <div class="table-wrap" style="margin-bottom:12px;">
                    <table>
                        <tr><th scope="row" style="width:160px;">Project</th><td><%= esc(project.getTitle()) %></td></tr>
                        <tr><th scope="row">Status</th>
                            <td><span class="badge <%= project.getStatusBadge() %>"><%= project.getStatusLabel() %></span>
                                <% if (project.getSubmittedAt() != null) { %>
                                    <span class="small muted">&nbsp;submitted <%= DateUtil.format(project.getSubmittedAt()) %></span>
                                <% } %>
                            </td></tr>
                        <tr><th scope="row">Problem</th><td style="white-space:pre-line;"><%= esc(project.getProblemStatement()) %></td></tr>
                        <tr><th scope="row">AI use</th><td style="white-space:pre-line;"><%= esc(project.getAiUseDeclaration()) %></td></tr>
                        <% if (project.getMentorFeedback() != null) { %>
                            <tr><th scope="row">Your feedback</th><td style="white-space:pre-line;"><%= esc(project.getMentorFeedback()) %></td></tr>
                        <% } %>
                    </table>
                </div>

                <% if (Project.STATUS_SUBMITTED.equals(project.getStatus())) { %>
                    <form action="<%= ctx %>/project" method="POST">
                        <input type="hidden" name="action"    value="review">
                        <input type="hidden" name="projectId" value="<%= project.getProjectId() %>">
                        <div class="form-group">
                            <label for="feedback<%= project.getProjectId() %>">Feedback for the team</label>
                            <textarea id="feedback<%= project.getProjectId() %>" name="feedback" rows="3" maxlength="2000"
                                      placeholder="What is good, and what should the team improve? (required when requesting a revision)"></textarea>
                        </div>
                        <div style="display:flex;gap:8px;flex-wrap:wrap;">
                            <button type="submit" name="decision" value="approved" class="btn btn-primary btn-sm"
                                    data-confirm="Approve this project? Team members will then be eligible for their Level Two certificate.">
                                <iconify-icon icon="tabler:check" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Approve
                            </button>
                            <button type="submit" name="decision" value="revision_requested" class="btn btn-accent btn-sm">
                                <iconify-icon icon="tabler:arrow-back-up" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Request Revision
                            </button>
                        </div>
                    </form>
                <% } else if (project.isEditable()) { %>
                    <p class="small muted">Waiting for the team to submit the project.</p>
                <% } %>
            <% } %>
        </section>
    <% } } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
