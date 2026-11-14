<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    Team workspace (FR13, FR14, FR17). Shared by participants (their own team),
    mentors (their teams) and admins. TeamServlet supplies team, members,
    project, mentor and messages. Phone numbers are never shown (privacy, report 8.2).
--%>
<%
    User    viewer  = (User)    session.getAttribute("loggedInUser");
    Team    team    = (Team)    request.getAttribute("team");
    Project project = (Project) request.getAttribute("project");
    User    mentor  = (User)    request.getAttribute("mentor");
    List<Participant> members = (List<Participant>) request.getAttribute("members");
    if (members == null) members = new ArrayList<>();
    List<Message> messages = (List<Message>) request.getAttribute("messages");
    if (messages == null) messages = new ArrayList<>();
    String ctx = request.getContextPath();
    if (team == null) { response.sendRedirect(ctx + "/login"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= esc(team.getName()) %> — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1><%= esc(team.getName()) %></h1>
    <p>Focus area: <%= esc(team.getFocusLabel()) %> &middot; <%= members.size() %> members</p>
</div></div>

<main class="main-content" id="main">
    <% if (!(viewer instanceof Participant)) { %>
        <p style="margin-bottom:14px;">
            <a href="<%= ctx %><%= viewer instanceof Admin ? "/admin?page=teams" : "/project" %>" class="btn btn-outline btn-sm">
                <iconify-icon icon="tabler:arrow-left" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Back
            </a>
        </p>
    <% } %>
    <div class="two-col">

        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:users-group" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Team Members</div>
            <% if (members.isEmpty()) { %>
                <p class="muted">No members yet.</p>
            <% } else { for (Participant m : members) { %>
                <div style="display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid var(--border);">
                    <div class="nav-avatar" style="width:36px;height:36px;flex-shrink:0;" aria-hidden="true">
                        <%= esc(m.getFullName().substring(0, 1).toUpperCase()) %>
                    </div>
                    <div>
                        <div style="font-weight:600;font-size:.9rem;">
                            <%= esc(m.getFullName()) %>
                            <% if (m.getUserId() == viewer.getUserId()) { %><span class="badge badge-grey">You</span><% } %>
                        </div>
                        <div class="small muted">
                            <iconify-icon icon="tabler:map-pin" width="13" height="13" style="vertical-align:-2px;"></iconify-icon>
                            <%= esc(m.getCountry()) %><%= m.getDistrict() != null ? ", " + esc(m.getDistrict()) : "" %>
                        </div>
                    </div>
                </div>
            <% } } %>

            <div style="margin-top:16px;padding:12px;background:var(--bg);border-radius:var(--radius);">
                <div class="small muted" style="text-transform:uppercase;letter-spacing:.05em;">Mentor</div>
                <% if (mentor instanceof Mentor) { Mentor mt = (Mentor) mentor; %>
                    <div style="font-weight:600;margin-top:2px;"><%= esc(mt.getFullName()) %></div>
                    <div class="small muted"><%= esc(mt.getExpertise()) %> &middot; <%= esc(mt.getEmail()) %></div>
                <% } else { %>
                    <div class="muted" style="margin-top:2px;">Not assigned yet</div>
                <% } %>
            </div>
        </div>

        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:bulb" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Impact Project</div>
            <% if (project == null) { %>
                <p class="muted">This team has not started a project yet.</p>
                <% if (viewer instanceof Participant) { %>
                    <a href="<%= ctx %>/project" class="btn btn-primary btn-sm" style="margin-top:10px;">
                        <iconify-icon icon="tabler:rocket" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Start Project
                    </a>
                <% } %>
            <% } else { %>
                <p><strong><%= esc(project.getTitle()) %></strong></p>
                <span class="badge <%= project.getStatusBadge() %>" style="margin:6px 0;"><%= project.getStatusLabel() %></span>
                <p class="small" style="margin-top:10px;white-space:pre-line;"><%= esc(project.getProblemStatement()) %></p>
                <% if (project.getMentorFeedback() != null && !project.getMentorFeedback().isBlank()) { %>
                    <div class="alert alert-info" style="margin-top:10px;display:block;">
                        <strong>Mentor feedback:</strong><br><%= esc(project.getMentorFeedback()) %>
                    </div>
                <% } %>
                <% if (viewer instanceof Participant) { %>
                    <a href="<%= ctx %>/project" class="btn btn-outline btn-sm" style="margin-top:10px;">
                        <iconify-icon icon="tabler:edit" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> View / Edit Project
                    </a>
                <% } %>
            <% } %>
        </div>
    </div>

    <%-- ===== Team discussion (FR17) ===== --%>
    <div class="card" id="chat">
        <div class="card-title">
            <iconify-icon icon="tabler:messages" width="18" height="18"></iconify-icon> Team Discussion
            <span class="small muted" style="text-transform:none;letter-spacing:0;font-weight:500;margin-left:auto;">
                Be respectful &middot; use <iconify-icon icon="tabler:flag" width="12" height="12"></iconify-icon> to report a harmful or misleading message
            </span>
        </div>

        <div class="chat-box" id="chatBox" aria-live="polite">
            <% if (messages.isEmpty()) { %>
                <p class="muted small" style="text-align:center;padding:20px 0;">
                    No messages yet. Say hello to your team and share your first project idea!
                </p>
            <% } %>
            <% for (Message m : messages) {
                   String cls = m.isFrom(viewer) ? "mine" : ("PARTICIPANT".equals(m.getSenderRole()) ? "" : "staff");
                   if (m.isFlagged()) cls += " flagged";
            %>
                <div class="chat-msg <%= cls %>">
                    <div class="chat-meta">
                        <strong><%= m.isFrom(viewer) ? "You" : esc(m.getSenderName()) %></strong>
                        <% if (!"PARTICIPANT".equals(m.getSenderRole())) { %>
                            <span class="badge badge-blue" style="padding:1px 7px;"><%= esc(m.getSenderRole().toLowerCase()) %></span>
                        <% } %>
                        <span><%= DateUtil.format(m.getSentAt()) %></span>
                        <% if (!m.isFrom(viewer) && !m.isFlagged()) { %>
                            <form method="POST" action="<%= ctx %>/team" style="display:inline;"
                                  onsubmit="return confirm('Report this message to the administrator?');">
                                <input type="hidden" name="action" value="flag">
                                <input type="hidden" name="teamId" value="<%= team.getTeamId() %>">
                                <input type="hidden" name="messageId" value="<%= m.getMessageId() %>">
                                <button class="chat-flag-btn" title="Flag as inappropriate or misleading" aria-label="Flag message">
                                    <iconify-icon icon="tabler:flag" width="13" height="13"></iconify-icon>
                                </button>
                            </form>
                        <% } %>
                    </div>
                    <div class="chat-bubble">
                        <% if (m.isFlagged()) { %>
                            <iconify-icon icon="tabler:alert-triangle" width="13" height="13"></iconify-icon>
                            Flagged — waiting for review by an administrator.
                        <% } else { %><%= esc(m.getBody()) %><% } %>
                    </div>
                </div>
            <% } %>
        </div>

        <form method="POST" action="<%= ctx %>/team" class="chat-form">
            <input type="hidden" name="action" value="send">
            <input type="hidden" name="teamId" value="<%= team.getTeamId() %>">
            <textarea id="body" name="body" aria-label="Message to your team" required maxlength="<%= Message.MAX_LENGTH %>" rows="2"
                      placeholder="Write a message to your team..."></textarea>
            <button type="submit" class="btn btn-primary">
                <iconify-icon icon="tabler:send" width="16" height="16"></iconify-icon> Send
            </button>
        </form>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
<script>
    // Show the newest message first time the page opens
    var box = document.getElementById('chatBox');
    if (box) box.scrollTop = box.scrollHeight;
</script>
</body>
</html>
