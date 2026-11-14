<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil" %>
<%--
    Impact Project page for a team member (FR15). ProjectServlet supplies
    "project" (may be null) and "team". The AI-use declaration is required
    before a project can be saved (responsible AI, report section 8.5).
--%>
<%
    Project project = (Project) request.getAttribute("project");
    Team    team    = (Team)    request.getAttribute("team");
    String  ctx     = request.getContextPath();
    boolean canEdit = (project == null || project.isEditable());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Impact Project — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Impact Project</h1>
    <p><%= team != null ? esc(team.getName()) + " &middot; " + esc(team.getFocusLabel()) : "" %></p>
</div></div>

<main class="main-content" id="main">

    <% if (project != null) { %>
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:progress-check" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Project Status</div>
            <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
                <strong><%= esc(project.getTitle()) %></strong>
                <span class="badge <%= project.getStatusBadge() %>"><%= project.getStatusLabel() %></span>
            </div>
            <% if (project.getSubmittedAt() != null) { %>
                <p class="small muted" style="margin-top:6px;">Last submitted <%= DateUtil.format(project.getSubmittedAt()) %></p>
            <% } %>
            <% if (Project.STATUS_SUBMITTED.equals(project.getStatus())) { %>
                <p class="small" style="margin-top:10px;">Your mentor is reviewing the project. You can edit it again if they request a revision.</p>
            <% } else if (Project.STATUS_APPROVED.equals(project.getStatus())) { %>
                <p class="small" style="margin-top:10px;">Congratulations — your project is approved! The YEP admin can now issue your Level Two certificate.</p>
            <% } %>
            <% if (project.getMentorFeedback() != null && !project.getMentorFeedback().isBlank()) { %>
                <div class="alert alert-info" style="margin-top:12px;display:block;">
                    <strong>Mentor feedback:</strong><br><%= esc(project.getMentorFeedback()) %>
                </div>
            <% } %>
            <% if (!canEdit) { %>
                <div style="margin-top:14px;">
                    <div class="small muted" style="text-transform:uppercase;letter-spacing:.05em;">Problem statement</div>
                    <p style="white-space:pre-line;margin-top:4px;"><%= esc(project.getProblemStatement()) %></p>
                    <div class="small muted" style="text-transform:uppercase;letter-spacing:.05em;margin-top:10px;">AI-use declaration</div>
                    <p style="white-space:pre-line;margin-top:4px;"><%= esc(project.getAiUseDeclaration()) %></p>
                </div>
            <% } %>
        </div>
    <% } %>

    <% if (canEdit) { %>
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:edit" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> <%= project == null ? "Start Your Project" : "Edit Project" %></div>
            <form action="<%= ctx %>/project" method="POST">
                <input type="hidden" name="action" value="save">
                <div class="form-group">
                    <label for="title">Project Title *</label>
                    <input type="text" id="title" name="title" required minlength="5" maxlength="200"
                           value="<%= project != null ? esc(project.getTitle()) : "" %>"
                           placeholder="A short, descriptive title">
                </div>
                <div class="form-group">
                    <label for="problemStatement">Problem Statement *</label>
                    <textarea id="problemStatement" name="problemStatement" required minlength="20" rows="5"
                              placeholder="What problem does your project solve, and for whom?"
                    ><%= project != null && project.getProblemStatement() != null ? esc(project.getProblemStatement()) : "" %></textarea>
                </div>
                <div class="form-group">
                    <label for="aiUseDeclaration">AI-Use Declaration *</label>
                    <span class="form-hint" id="aiHint">Describe how your team used AI tools (e.g. ChatGPT), or write "No AI tools were used".</span>
                    <textarea id="aiUseDeclaration" name="aiUseDeclaration" required minlength="5" rows="3" aria-describedby="aiHint"
                              placeholder="e.g. We used ChatGPT to brainstorm ideas. All facts were checked and the text was written by the team."
                    ><%= project != null && project.getAiUseDeclaration() != null ? esc(project.getAiUseDeclaration()) : "" %></textarea>
                </div>
                <button type="submit" class="btn btn-primary">
                    <iconify-icon icon="tabler:device-floppy" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Save Draft
                </button>
            </form>
        </div>
    <% } %>

    <% if (project != null && project.isEditable()) { %>
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:send" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Submit for Mentor Review</div>
            <p style="margin-bottom:12px;">Save your latest changes first. After submitting, the project is locked until your mentor reviews it.</p>
            <form action="<%= ctx %>/project" method="POST">
                <input type="hidden" name="action" value="submit">
                <button type="submit" class="btn btn-accent"
                        data-confirm="Submit the project for review? You won't be able to edit it until your mentor responds.">
                    <iconify-icon icon="tabler:send" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Submit Project
                </button>
            </form>
        </div>
    <% } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
