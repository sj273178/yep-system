<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    Level One sessions for participants (FR08). Each session shows its status:
    Not started → Joined (quiz pending) → Completed (quiz score).
    SessionServlet supplies: sessions, attendedModes, quizScores, questionCount.
--%>
<%
    Participant participant = (Participant) session.getAttribute("loggedInUser");
    List<Activity> sessions          = (List<Activity>) request.getAttribute("sessions");
    Map<Integer, String>  attended   = (Map<Integer, String>)  request.getAttribute("attendedModes");
    Map<Integer, Double>  quizScores = (Map<Integer, Double>)  request.getAttribute("quizScores");
    Map<Integer, Integer> qCount     = (Map<Integer, Integer>) request.getAttribute("questionCount");
    if (sessions == null) { response.sendRedirect(request.getContextPath() + "/sessions"); return; }

    int completed = 0;
    for (Activity s : sessions) {
        boolean hasQuiz = qCount.getOrDefault(s.getActivityId(), 0) > 0;
        if (attended.containsKey(s.getActivityId()) && (!hasQuiz || quizScores.containsKey(s.getActivityId()))) completed++;
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sessions — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Level One Sessions</h1>
    <p>Complete a session in three steps: read the notes, join (video, audio or notes), then take the short quiz.</p>
</div></div>

<main class="main-content" id="main">
    <div class="card" style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;">
        <div>
            <strong><%= completed %></strong> of <%= sessions.size() %> sessions completed.
            <% if (participant.getVeLevel() == 1) { %>
                <span class="small muted">&nbsp;Level Two needs <%= Participant.MIN_SESSIONS %> sessions and a <%= (int) Participant.PROMOTION_AVERAGE %>% average.</span>
            <% } %>
        </div>
        <a href="<%= ctx %>/participant/dashboard.jsp" class="btn btn-outline btn-sm">My progress</a>
    </div>

    <% if (sessions.isEmpty()) { %>
        <div class="card empty-state">
            <div style="display:flex;justify-content:center;margin-bottom:12px;">
                <iconify-icon icon="tabler:calendar-off" width="48" height="48" style="color:var(--text-muted);"></iconify-icon>
            </div>
            <p>No sessions available yet. Check back soon.</p>
        </div>
    <% } else { for (Activity s : sessions) {
        int id = s.getActivityId();
        boolean joined  = attended.containsKey(id);
        boolean hasQuiz = qCount.getOrDefault(id, 0) > 0;
        Double score    = quizScores.get(id);
        String status, badge, button;
        if (joined && (score != null || !hasQuiz)) {
            status = score != null ? "Completed · " + String.format("%.0f", score) + "%" : "Completed";
            badge = "badge-green"; button = "Review";
        } else if (joined) {
            status = "Quiz pending"; badge = "badge-gold"; button = "Take quiz";
        } else if (!s.hasStarted()) {
            status = "Upcoming"; badge = "badge-purple"; button = "Preview";
        } else {
            status = "Not started"; badge = "badge-grey"; button = "Start";
        } %>
        <article class="session-card">
            <div style="flex:1;">
                <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:8px;">
                    <h2 class="session-card-title" style="font-size:1rem;margin:0;">
                        <a href="<%= ctx %>/sessions?id=<%= id %>" style="color:inherit;"><%= esc(s.getTitle()) %></a>
                    </h2>
                    <span class="badge <%= badge %>"><%= status %></span>
                    <% if (s.isLowBandwidth()) { %>
                        <span class="badge badge-blue" style="gap:4px;"><iconify-icon icon="tabler:wifi-off" width="11" height="11"></iconify-icon> Low data</span>
                    <% } %>
                </div>
                <div class="session-card-meta" style="display:flex;align-items:center;gap:14px;flex-wrap:wrap;">
                    <span style="display:inline-flex;align-items:center;gap:4px;"><iconify-icon icon="tabler:tag" width="13" height="13"></iconify-icon> <%= esc(s.getTopic()) %></span>
                    <span style="display:inline-flex;align-items:center;gap:4px;"><iconify-icon icon="tabler:calendar" width="13" height="13"></iconify-icon> <%= DateUtil.format(s.getSessionDate()) %></span>
                    <span style="display:inline-flex;align-items:center;gap:4px;"><iconify-icon icon="tabler:clock" width="13" height="13"></iconify-icon> <%= s.getDurationMins() %> min</span>
                    <% if (hasQuiz) { %>
                        <span style="display:inline-flex;align-items:center;gap:4px;"><iconify-icon icon="tabler:checklist" width="13" height="13"></iconify-icon> <%= qCount.get(id) %>-question quiz</span>
                    <% } %>
                </div>
                <% if (s.getDescription() != null) { %>
                    <div class="session-card-desc"><%= esc(s.getDescription()) %></div>
                <% } %>
            </div>
            <div style="flex-shrink:0;">
                <a href="<%= ctx %>/sessions?id=<%= id %>" class="btn btn-sm <%= "Start".equals(button) || "Take quiz".equals(button) ? "btn-primary" : "btn-outline" %>">
                    <%= button %> &rarr;
                </a>
            </div>
        </article>
    <% } } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
