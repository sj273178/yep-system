<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.dao.*,java.util.*" %>
<%-- Mentor dashboard (FR06, FR14, FR16). AuthFilter guarantees a logged-in mentor. --%>
<%
    Mentor mentor = (Mentor) session.getAttribute("loggedInUser");
    ProjectDAO projectDAO = new ProjectDAO();

    List<Team> myTeams = new TeamDAO().findByMentor(mentor.getUserId());
    int teamCount = myTeams.size();

    int awaitingReview = 0, approved = 0;
    Map<Integer, Project> projects = new HashMap<>();
    for (Team t : myTeams) {
        Project p = projectDAO.findByTeam(t.getTeamId());
        if (p != null) {
            projects.put(t.getTeamId(), p);
            if (Project.STATUS_SUBMITTED.equals(p.getStatus())) awaitingReview++;
            if (Project.STATUS_APPROVED.equals(p.getStatus()))  approved++;
        }
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mentor Dashboard — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Welcome, <%= esc(mentor.getFullName()) %></h1>
    <p>Mentor<%= mentor.getExpertise() != null ? " &middot; " + esc(mentor.getExpertise()) : "" %></p>
</div></div>

<main class="main-content" id="main">
    <% if (awaitingReview > 0) { %>
        <div class="alert alert-warning">
            <span><strong><%= awaitingReview %></strong> project<%= awaitingReview == 1 ? "" : "s" %> waiting for your review.
            <a href="<%= ctx %>/project" style="font-weight:600;margin-left:6px;">Review now &rarr;</a></span>
        </div>
    <% } %>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:users-group" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= teamCount %></div>
            <div class="label">My Teams</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:user-plus" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= Math.max(0, mentor.getMaxTeams() - teamCount) %></div>
            <div class="label">Free Slots</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:hourglass" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= awaitingReview %></div>
            <div class="label">Awaiting Review</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:circle-check" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= approved %></div>
            <div class="label">Approved</div>
        </div>
    </div>

    <div class="two-col">
        <div class="card">
            <div class="card-title">My Teams</div>
            <% if (myTeams.isEmpty()) { %>
                <div class="empty-state" style="padding:20px 0;">
                    <div style="display:flex;justify-content:center;margin-bottom:10px;">
                        <iconify-icon icon="tabler:users-minus" width="40" height="40" style="color:var(--text-muted);"></iconify-icon>
                    </div>
                    <p>No teams assigned yet. The YEP admin will assign Level Two teams to you.</p>
                </div>
            <% } else { for (Team t : myTeams) {
                   Project p = projects.get(t.getTeamId()); %>
                <a href="<%= ctx %>/team?teamId=<%= t.getTeamId() %>"
                   style="display:flex;align-items:center;gap:12px;padding:12px;background:var(--bg);
                          border-radius:var(--radius);margin-bottom:8px;color:inherit;text-decoration:none;">
                    <div style="width:38px;height:38px;border-radius:9px;background:var(--primary-light);color:var(--primary-darker);
                                display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                        <iconify-icon icon="tabler:users-group" width="20" height="20"></iconify-icon>
                    </div>
                    <div style="flex:1;min-width:0;">
                        <div style="font-weight:600;font-size:.88rem;"><%= esc(t.getName()) %></div>
                        <div class="small muted"><%= esc(t.getFocusLabel()) %> &middot; <%= t.getMemberCount() %> members</div>
                    </div>
                    <% if (p == null) { %>
                        <span class="badge badge-grey">No project</span>
                    <% } else { %>
                        <span class="badge <%= p.getStatusBadge() %>"><%= p.getStatusLabel() %></span>
                    <% } %>
                </a>
            <% } } %>
        </div>

        <div class="card">
            <div class="card-title">Mentoring Capacity</div>
            <div class="bar-head">
                <span>Teams assigned</span>
                <span><%= teamCount %> / <%= mentor.getMaxTeams() %></span>
            </div>
            <div class="progress-track">
                <div class="progress-fill" style="width:<%= mentor.getMaxTeams() > 0 ? Math.min(100, teamCount * 100 / mentor.getMaxTeams()) : 0 %>%;"></div>
            </div>
            <p class="small muted" style="margin-top:10px;">Each mentor guides at most <%= mentor.getMaxTeams() %> teams so every team gets enough support.</p>

            <div class="action-grid" style="margin-top:16px;">
                <a href="<%= ctx %>/project" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:folder-open" width="22" height="22"></iconify-icon></span>
                    <span class="label">Review Projects</span>
                </a>
                <a href="<%= ctx %>/verify" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:shield-check" width="22" height="22"></iconify-icon></span>
                    <span class="label">Verify Certificate</span>
                </a>
            </div>
        </div>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
