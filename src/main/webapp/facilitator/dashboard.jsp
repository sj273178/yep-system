<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.dao.*,com.yep.util.DateUtil,java.util.*,java.time.*" %>
<%-- Facilitator dashboard (FR06). AuthFilter guarantees a logged-in facilitator. --%>
<%
    Facilitator facilitator = (Facilitator) session.getAttribute("loggedInUser");
    ActivityDAO actDAO = new ActivityDAO();

    List<Activity> mySessions = actDAO.findByFacilitator(facilitator.getUserId());
    Map<Integer, Integer> attendees = actDAO.countAttendeesPerActivity();
    int scoresRecorded = new AssessmentDAO().countByAssessor(facilitator.getUserId());
    LocalDateTime now = LocalDateTime.now();

    int lowBwCount = 0, totalMins = 0, totalAttendance = 0;
    List<Activity> upcoming = new ArrayList<>();
    for (Activity a : mySessions) {
        if (a.getSessionDate() != null && a.getSessionDate().isAfter(now)) upcoming.add(a);
        if (a.isLowBandwidth()) lowBwCount++;
        totalMins += a.getDurationMins();
        totalAttendance += attendees.getOrDefault(a.getActivityId(), 0);
    }
    upcoming.sort(Comparator.comparing(Activity::getSessionDate));
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Facilitator Dashboard — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Welcome, <%= esc(facilitator.getFullName()) %></h1>
    <p>Facilitator<%= facilitator.getOrganisation() != null ? " &middot; " + esc(facilitator.getOrganisation()) : "" %></p>
</div></div>

<main class="main-content" id="main">
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:calendar-event" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= mySessions.size() %></div>
            <div class="label">My Sessions</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:users" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= totalAttendance %></div>
            <div class="label">Total Attendance</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:clipboard-check" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= scoresRecorded %></div>
            <div class="label">Scores Recorded</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:wifi-off" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= lowBwCount %></div>
            <div class="label">Low-Bandwidth Sessions</div>
        </div>
    </div>

    <div class="two-col">
        <div class="card">
            <div class="card-title">Upcoming Sessions</div>
            <% if (upcoming.isEmpty()) { %>
                <div class="empty-state" style="padding:20px 0;">
                    <div style="display:flex;justify-content:center;margin-bottom:10px;">
                        <iconify-icon icon="tabler:calendar-off" width="40" height="40" style="color:var(--text-muted);"></iconify-icon>
                    </div>
                    <p>No upcoming sessions. Schedule one to engage participants.</p>
                </div>
            <% } else { for (Activity a : upcoming.subList(0, Math.min(4, upcoming.size()))) { %>
                <div style="display:flex;align-items:center;gap:12px;padding:12px;background:var(--bg);
                            border-radius:var(--radius);margin-bottom:8px;">
                    <div style="width:38px;height:38px;border-radius:9px;background:var(--primary-light);color:var(--primary-darker);
                                display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                        <iconify-icon icon="tabler:calendar-event" width="20" height="20"></iconify-icon>
                    </div>
                    <div style="flex:1;min-width:0;">
                        <div style="font-weight:600;font-size:.88rem;"><%= esc(a.getTitle()) %></div>
                        <div class="small muted"><%= DateUtil.format(a.getSessionDate()) %> &middot; <%= a.getDurationMins() %> min</div>
                    </div>
                    <% if (a.isLowBandwidth()) { %><span class="badge badge-blue">Low BW</span><% } %>
                </div>
            <% } } %>
            <p class="small muted" style="margin-top:10px;">
                Total teaching time: <strong><%= totalMins / 60 %>h <%= totalMins % 60 %>m</strong>
            </p>
        </div>

        <div class="card">
            <div class="card-title">Quick Actions</div>
            <div class="action-grid">
                <a href="<%= ctx %>/sessions?action=create" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:calendar-plus" width="22" height="22"></iconify-icon></span>
                    <span class="label">New Session</span>
                </a>
                <a href="<%= ctx %>/sessions" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:list-details" width="22" height="22"></iconify-icon></span>
                    <span class="label">Manage Sessions</span>
                </a>
                <a href="<%= ctx %>/quiz" class="action-card">
                    <span class="icon"><iconify-icon icon="tabler:clipboard-list" width="22" height="22"></iconify-icon></span>
                    <span class="label">Record Scores</span>
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
