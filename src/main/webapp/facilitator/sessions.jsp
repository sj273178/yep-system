<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%-- All Level One sessions; facilitators can score their own (FR07, FR10). --%>
<%
    User user = (User) session.getAttribute("loggedInUser");
    List<Activity> sessions = (List<Activity>) request.getAttribute("sessions");
    Map<Integer, Integer> attendees = (Map<Integer, Integer>) request.getAttribute("attendees");
    Map<Integer, Integer> questionCount = (Map<Integer, Integer>) request.getAttribute("questionCount");
    if (questionCount == null) questionCount = new HashMap<>();
    if (sessions == null) sessions = new ArrayList<>();
    if (attendees == null) attendees = new HashMap<>();
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Sessions — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Manage Sessions</h1>
    <p>All Level One sessions on the platform. You can record scores for the sessions you run.</p>
</div></div>
<main class="main-content" id="main">
    <div style="margin-bottom:16px;">
        <a href="<%= ctx %>/sessions?action=create" class="btn btn-primary">
            <iconify-icon icon="tabler:calendar-plus" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> New Session
        </a>
    </div>
    <% if (sessions.isEmpty()) { %>
        <div class="card empty-state">
            <div style="display:flex;justify-content:center;margin-bottom:10px;"><iconify-icon icon="tabler:calendar-off" width="44" height="44" style="color:var(--text-muted);"></iconify-icon></div>
            <p>No sessions yet. Create the first one!</p>
        </div>
    <% } else { %>
        <div class="table-wrap">
            <table>
                <thead><tr>
                    <th scope="col">Title</th><th scope="col">Topic</th><th scope="col">Date</th>
                    <th scope="col">Duration</th><th scope="col">Low BW</th><th scope="col">Quiz</th><th scope="col">Attended</th><th scope="col">Actions</th>
                </tr></thead>
                <tbody>
                <% for (Activity s : sessions) {
                       boolean mine = s.getFacilitatorId() == user.getUserId(); %>
                    <tr>
                        <td><strong><%= esc(s.getTitle()) %></strong></td>
                        <td><%= esc(s.getTopic()) %></td>
                        <td style="white-space:nowrap;"><%= DateUtil.format(s.getSessionDate()) %></td>
                        <td><%= s.getDurationMins() %> min</td>
                        <td><span class="badge <%= s.isLowBandwidth() ? "badge-blue" : "badge-grey" %>"><%= s.isLowBandwidth() ? "Yes" : "No" %></span></td>
                        <td><% int qc = questionCount.getOrDefault(s.getActivityId(), 0); %>
                            <span class="badge <%= qc > 0 ? "badge-green" : "badge-gold" %>"><%= qc > 0 ? qc + " questions" : "None" %></span></td>
                        <td><%= attendees.getOrDefault(s.getActivityId(), 0) %></td>
                        <td>
                            <% if (mine) { %>
                                <div class="row-actions">
                                <a href="<%= ctx %>/questions?activityId=<%= s.getActivityId() %>" class="btn btn-outline btn-sm">
                                    <iconify-icon icon="tabler:list-check" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Quiz
                                </a>
                                <a href="<%= ctx %>/quiz?activityId=<%= s.getActivityId() %>" class="btn btn-primary btn-sm">
                                    <iconify-icon icon="tabler:checklist" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Scores
                                </a>
                                </div>
                            <% } else { %>
                                <span class="small muted">Another facilitator</span>
                            <% } %>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    <% } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
