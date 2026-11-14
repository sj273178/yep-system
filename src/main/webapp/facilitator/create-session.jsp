<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.util.ValidationUtil" %>
<%--
    Create a Level One session (FR07). If SessionServlet finds a problem it
    forwards back here with "error"; v() refills what the facilitator typed.
--%>
<%!
    static String v(jakarta.servlet.http.HttpServletRequest r, String name, String fallback) {
        String value = r.getParameter(name);
        return ValidationUtil.escapeHtml(value != null ? value : fallback);
    }
%>
<%
    String error = (String) request.getAttribute("error");
    String ctx   = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Session — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Create Level One Session</h1>
    <p>Add the session details and learning notes. Next you will add the quiz participants take after joining.</p>
</div></div>
<main class="main-content" id="main">
    <div class="card" style="max-width:640px;">
        <% if (error != null) { %>
            <div class="alert alert-error" role="alert"><%= esc(error) %></div>
        <% } %>
        <form action="<%= ctx %>/sessions" method="POST">
            <input type="hidden" name="action" value="create">
            <div class="form-group">
                <label for="title">Session Title *</label>
                <input type="text" id="title" name="title" required minlength="3" maxlength="200"
                       value="<%= v(request, "title", "") %>" placeholder="e.g. Introduction to AI Literacy">
            </div>
            <div class="form-group">
                <label for="topic">Topic *</label>
                <input type="text" id="topic" name="topic" required maxlength="200" list="topicList"
                       value="<%= v(request, "topic", "") %>" placeholder="e.g. Digital Literacy">
                <datalist id="topicList">
                    <option>Digital Literacy</option><option>AI Literacy</option><option>Media Literacy</option>
                    <option>Critical Thinking</option><option>Intercultural Communication</option>
                    <option>Entrepreneurship</option><option>Employability</option>
                </datalist>
            </div>
            <div class="form-group">
                <label for="description">Description</label>
                <textarea id="description" name="description" rows="3"
                          placeholder="What will participants learn?"><%= v(request, "description", "") %></textarea>
            </div>
            <div class="form-group">
                <label for="notes">Learning notes</label>
                <span class="form-hint" id="notesHint">The low-data option: short notes participants read or download (a few paragraphs).</span>
                <textarea id="notes" name="notes" rows="8" aria-describedby="notesHint"
                          placeholder="Key ideas, examples and tips participants need for the quiz..."><%= v(request, "notes", "") %></textarea>
            </div>
            <div class="form-group">
                <label for="recordingUrl">Recording link (optional)</label>
                <input type="url" id="recordingUrl" name="recordingUrl" maxlength="500"
                       value="<%= v(request, "recordingUrl", "") %>" placeholder="https://...">
            </div>
            <div class="form-grid">
                <div class="form-group">
                    <label for="sessionDate">Date &amp; Time *</label>
                    <input type="datetime-local" id="sessionDate" name="sessionDate" required value="<%= v(request, "sessionDate", "") %>">
                </div>
                <div class="form-group">
                    <label for="durationMins">Duration (minutes) *</label>
                    <input type="number" id="durationMins" name="durationMins" required min="15" max="480"
                           value="<%= v(request, "durationMins", "60") %>">
                </div>
            </div>
            <div class="form-group">
                <div class="checkbox-row">
                    <input type="checkbox" id="lowBandwidth" name="lowBandwidth"
                        <%= request.getParameter("title") == null || "on".equals(request.getParameter("lowBandwidth")) ? "checked" : "" %>>
                    <label for="lowBandwidth">
                        Low-bandwidth friendly (audio-only stream and downloadable notes available)
                    </label>
                </div>
            </div>
            <div style="display:flex;gap:10px;">
                <button type="submit" class="btn btn-primary">
                    <iconify-icon icon="tabler:calendar-plus" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Create Session
                </button>
                <a href="<%= ctx %>/sessions" class="btn btn-outline">Cancel</a>
            </div>
        </form>
    </div>
</main>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
