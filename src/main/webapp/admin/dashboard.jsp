<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.dao.AuditLogDAO,com.yep.util.DateUtil,java.util.*" %>
<%-- Admin dashboard (FR06, FR17, NFR12). AdminServlet supplies the figures, flagged messages and recent activity. --%>
<%
    List<AuditLogDAO.Entry> recent = (List<AuditLogDAO.Entry>) request.getAttribute("recent");
    if (recent == null) { response.sendRedirect(request.getContextPath() + "/admin"); return; }
    int eligible  = (Integer) request.getAttribute("eligibleCount");
    int waiting   = (Integer) request.getAttribute("waitingCount");
    long noMentor = (Long)    request.getAttribute("noMentorCount");
    List<Message> flagged = (List<Message>) request.getAttribute("flagged");
    if (flagged == null) flagged = new ArrayList<>();
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>

<div class="page-header"><div class="container">
    <h1>Admin Dashboard</h1>
    <p>YEP Secretariat management panel</p>
</div></div>

<main class="main-content" id="main">
    <div class="stats-grid">
        <div class="stat-card">
            <span class="stat-icon"><iconify-icon icon="tabler:school" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= request.getAttribute("participants") %></div>
            <div class="label">Participants</div>
        </div>
        <div class="stat-card">
            <span class="stat-icon"><iconify-icon icon="tabler:calendar-event" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= request.getAttribute("sessions") %></div>
            <div class="label">Sessions</div>
        </div>
        <div class="stat-card">
            <span class="stat-icon"><iconify-icon icon="tabler:users-group" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= request.getAttribute("teams") %></div>
            <div class="label">Teams</div>
        </div>
        <div class="stat-card">
            <span class="stat-icon"><iconify-icon icon="tabler:certificate" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= request.getAttribute("certificates") %></div>
            <div class="label">Certificates</div>
        </div>
    </div>

    <% if (!flagged.isEmpty()) { %>
    <div class="card" style="border-color:#fcd34d;">
        <div class="card-title" style="color:var(--warning);">
            <iconify-icon icon="tabler:flag" width="18" height="18" style="color:var(--warning);"></iconify-icon>
            Flagged Team Messages (<%= flagged.size() %>) &mdash; please review
        </div>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Team</th><th>Written by</th><th>Message</th><th>Sent</th><th class="text-right">Decision</th></tr></thead>
                <tbody>
                <% for (Message m : flagged) { %>
                    <tr>
                        <td><a href="<%= ctx %>/team?teamId=<%= m.getTeamId() %>#chat"><%= esc(m.getTeamName()) %></a></td>
                        <td><%= esc(m.getSenderName()) %></td>
                        <td style="max-width:360px;white-space:pre-line;"><%= esc(m.getBody()) %></td>
                        <td class="small muted"><%= DateUtil.format(m.getSentAt()) %></td>
                        <td class="text-right">
                            <div class="row-actions" style="justify-content:flex-end;">
                                <form method="POST" action="<%= ctx %>/admin" class="inline-form">
                                    <input type="hidden" name="messageId" value="<%= m.getMessageId() %>">
                                    <button name="action" value="keepMessage" class="btn btn-sm btn-outline">Keep</button>
                                    <button name="action" value="deleteMessage" class="btn btn-sm btn-danger"
                                            onclick="return confirm('Delete this message permanently?');">Remove</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
    <% } %>

    <div class="two-col">
        <div class="card">
            <div class="card-title">Needs Attention</div>
            <div class="todo-item">
                <span><strong><%= eligible %></strong> participant(s) eligible for Level Two</span>
                <a href="<%= ctx %>/admin?page=promote" class="btn btn-sm <%= eligible > 0 ? "btn-primary" : "btn-outline" %>">Promote</a>
            </div>
            <div class="todo-item">
                <span><strong><%= waiting %></strong> Level Two participant(s) without a team</span>
                <a href="<%= ctx %>/admin?page=teams" class="btn btn-sm <%= waiting >= 3 ? "btn-primary" : "btn-outline" %>">Form teams</a>
            </div>
            <div class="todo-item">
                <span><strong><%= noMentor %></strong> team(s) without a mentor</span>
                <a href="<%= ctx %>/admin?page=teams" class="btn btn-sm <%= noMentor > 0 ? "btn-primary" : "btn-outline" %>">Assign</a>
            </div>
            <div class="todo-item">
                <span>Issue certificates to participants who qualify</span>
                <a href="<%= ctx %>/admin?page=certificates" class="btn btn-sm btn-outline">Certificates</a>
            </div>

            <div class="action-grid" style="margin-top:16px;">
                <a href="<%= ctx %>/admin?page=users" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:user-cog" width="22" height="22"></iconify-icon></span>
                    <span class="label">Manage Users</span>
                </a>
                <a href="<%= ctx %>/admin?page=reports" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:chart-bar" width="22" height="22"></iconify-icon></span>
                    <span class="label">Reports</span>
                </a>
                <a href="<%= ctx %>/opportunities" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:briefcase" width="22" height="22"></iconify-icon></span>
                    <span class="label">Post Opportunity</span>
                </a>
                <a href="<%= ctx %>/talent" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:id-badge-2" width="22" height="22"></iconify-icon></span>
                    <span class="label">Talent Directory</span>
                </a>
            </div>
        </div>

        <div class="card">
            <div class="card-title">Recent Activity <span class="small muted">(audit log)</span></div>
            <% if (recent.isEmpty()) { %>
                <p class="muted">No activity recorded yet.</p>
            <% } else { %>
                <ul class="activity-list">
                    <% for (AuditLogDAO.Entry e : recent) { %>
                        <li>
                            <time><%= DateUtil.format(e.getLoggedAt()) %></time>
                            <span><strong><%= esc(e.getUserName()) %></strong> &mdash; <%= esc(e.getActionLabel()) %>
                                <% if (e.getDetail() != null) { %><br><span class="small muted"><%= esc(e.getDetail()) %></span><% } %>
                            </span>
                        </li>
                    <% } %>
                </ul>
            <% } %>
        </div>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
