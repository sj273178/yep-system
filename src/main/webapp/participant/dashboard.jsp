<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.dao.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    Participant dashboard (FR06, FR11). AuthFilter has already checked that
    the user is a logged-in participant and refreshed their data.
--%>
<%
    Participant participant = (Participant) session.getAttribute("loggedInUser");

    int attendanceCount = new ActivityDAO().countAttendance(participant.getUserId());
    double averageScore = new AssessmentDAO().getAverageScore(participant.getUserId());
    String grade        = Participant.computeGrade(averageScore);
    List<Certificate> certificates = new CertificateDAO().findByParticipant(participant.getUserId());
    Team team           = participant.getTeamId() != null ? new TeamDAO().findById(participant.getTeamId()) : null;
    boolean qualifies   = participant.isEligibleForPromotion(attendanceCount, averageScore);

    // "Continue learning": sessions that have started but are not completed yet
    Map<Integer, String>  attendedModes = new ActivityDAO().findAttendanceModes(participant.getUserId());
    Map<Integer, Double>  quizScores    = new AssessmentDAO().findQuizScores(participant.getUserId());
    Map<Integer, Integer> questionCount = new QuizDAO().countQuestionsPerActivity();
    List<Activity> toDo = new ArrayList<>();
    for (Activity a : new ActivityDAO().findAll()) {
        boolean hasQuiz = questionCount.getOrDefault(a.getActivityId(), 0) > 0;
        boolean done = attendedModes.containsKey(a.getActivityId()) && (!hasQuiz || quizScores.containsKey(a.getActivityId()));
        if (a.hasStarted() && !done) toDo.add(a);
    }
    String ctx          = request.getContextPath();

    String gradeBadge = "Distinction".equals(grade) ? "badge-green"
                      : "Merit".equals(grade)       ? "badge-blue"
                      : "Pass".equals(grade)        ? "badge-gold" : "badge-red";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>

<div class="page-header">
    <div class="container" style="display:flex;align-items:center;gap:16px;flex-wrap:wrap;">
        <div style="width:52px;height:52px;background:rgba(255,255,255,.2);border-radius:50%;
                    display:flex;align-items:center;justify-content:center;
                    font-size:1.4rem;font-weight:800;color:white;flex-shrink:0;" aria-hidden="true">
            <%= esc(participant.getFullName().substring(0, 1).toUpperCase()) %>
        </div>
        <div>
            <h1>Hello, <%= esc(participant.getFullName().split(" ")[0]) %>!</h1>
            <p>Level <%= participant.getVeLevel() %> Participant &mdash; <%= esc(participant.getCountry()) %>
               &middot; Participant ID <%= participant.getUserId() %></p>
        </div>
    </div>
</div>

<main class="main-content" id="main">

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:book" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= attendanceCount %></div>
            <div class="label">Sessions Attended</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:chart-line" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= String.format("%.0f", averageScore) %>%</div>
            <div class="label">Average Score</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:star" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= participant.getPoints() %></div>
            <div class="label">Points Earned</div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><iconify-icon icon="tabler:certificate" width="22" height="22"></iconify-icon></div>
            <div class="number"><%= certificates.size() %></div>
            <div class="label">Certificates</div>
        </div>
    </div>

    <% if (participant.getVeLevel() == 1 || !toDo.isEmpty()) { %>
    <div class="card">
        <div class="card-title"><iconify-icon icon="tabler:player-play" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Continue Learning</div>
        <% if (toDo.isEmpty()) { %>
            <p class="muted">You have completed every available session. New sessions will appear here.</p>
        <% } else { for (Activity a : toDo.subList(0, Math.min(3, toDo.size()))) {
               boolean joined = attendedModes.containsKey(a.getActivityId()); %>
            <div class="todo-item">
                <span><strong><%= esc(a.getTitle()) %></strong>
                    <span class="small muted">&middot; <%= esc(a.getTopic()) %><%= joined ? " · quiz pending" : "" %></span></span>
                <a href="<%= ctx %>/sessions?id=<%= a.getActivityId() %>" class="btn btn-primary btn-sm"><%= joined ? "Take quiz" : "Start" %></a>
            </div>
        <% } } %>
    </div>
    <% } %>

    <div class="two-col">

        <%-- Progress towards Level Two --%>
        <div class="card">
            <div class="card-title">Your Progress</div>

            <div class="bar-head">
                <span>Average score (need <%= (int) Participant.PROMOTION_AVERAGE %>%+)</span>
                <span><%= String.format("%.1f", averageScore) %>%</span>
            </div>
            <div class="progress-track" role="progressbar" aria-valuenow="<%= (int) averageScore %>" aria-valuemin="0" aria-valuemax="100">
                <div class="progress-fill" style="width:<%= Math.min(averageScore, 100) %>%;"></div>
            </div>

            <div class="bar-head" style="margin-top:16px;">
                <span>Sessions attended (need <%= Participant.MIN_SESSIONS %>+)</span>
                <span><%= attendanceCount %> / <%= Participant.MIN_SESSIONS %></span>
            </div>
            <div class="progress-track" role="progressbar" aria-valuenow="<%= attendanceCount %>" aria-valuemin="0" aria-valuemax="<%= Participant.MIN_SESSIONS %>">
                <div class="progress-fill" style="width:<%= Math.min(attendanceCount * 100.0 / Participant.MIN_SESSIONS, 100) %>%;"></div>
            </div>

            <div style="margin-top:20px;display:flex;align-items:center;justify-content:space-between;
                        background:var(--bg);border-radius:var(--radius);padding:12px 16px;">
                <div>
                    <div class="small muted" style="text-transform:uppercase;letter-spacing:.05em;">Grade</div>
                    <div style="font-weight:700;font-size:1rem;margin-top:2px;"><%= grade %></div>
                </div>
                <span class="badge <%= gradeBadge %>">Level <%= participant.getVeLevel() %></span>
            </div>

            <% if (participant.getVeLevel() == 2) { %>
                <div class="alert alert-success" style="margin:12px 0 0;">
                    You are on Level Two.
                    <%= team != null ? "Your team is " + esc(team.getName()) + "." : "You will be placed in a cross-country team soon." %>
                </div>
            <% } else if (qualifies) { %>
                <div class="alert alert-success" style="margin:12px 0 0;">
                    You qualify for Level Two! The YEP admin will promote you soon.
                </div>
            <% } else { %>
                <p class="small muted" style="margin-top:12px;text-align:center;">
                    Attend <%= Participant.MIN_SESSIONS %> sessions with a <%= (int) Participant.PROMOTION_AVERAGE %>%+ average to qualify for Level Two.
                </p>
            <% } %>
        </div>

        <div>
            <%-- Certificates --%>
            <div class="card">
                <div class="card-title">Certificates</div>
                <% if (certificates.isEmpty()) { %>
                    <div class="empty-state" style="padding:20px 0;">
                        <div style="display:flex;justify-content:center;margin-bottom:10px;">
                            <iconify-icon icon="tabler:certificate-off" width="40" height="40" style="color:var(--text-muted);"></iconify-icon>
                        </div>
                        <p>Complete <%= Participant.MIN_SESSIONS %> sessions with a <%= (int) Participant.CERTIFICATE_AVERAGE %>%+ average to earn your Level One certificate.</p>
                    </div>
                <% } else { for (Certificate cert : certificates) { %>
                    <div style="display:flex;align-items:center;gap:12px;padding:12px;
                                background:var(--bg);border-radius:var(--radius);margin-bottom:8px;">
                        <div style="width:38px;height:38px;border-radius:9px;background:var(--primary-light);
                                    display:flex;align-items:center;justify-content:center;flex-shrink:0;">
                            <iconify-icon icon="tabler:file-certificate" width="20" height="20" style="color:var(--primary-darker);"></iconify-icon>
                        </div>
                        <div style="flex:1;min-width:0;">
                            <div style="font-weight:600;font-size:.85rem;"><%= esc(cert.getTypeLabel()) %></div>
                            <div class="small muted">Issued <%= DateUtil.format(cert.getIssuedDate()) %></div>
                            <code style="font-size:.72rem;background:var(--white);border:1px solid var(--border);
                                         padding:1px 6px;border-radius:4px;display:inline-block;margin-top:3px;">
                                <%= esc(cert.getVerificationCode()) %>
                            </code>
                        </div>
                        <a href="<%= ctx %>/certificate?code=<%= esc(cert.getVerificationCode()) %>" class="btn btn-primary btn-sm">
                            <iconify-icon icon="tabler:eye" width="13" height="13"></iconify-icon> View
                        </a>
                    </div>
                <% } } %>
            </div>

            <div class="card" style="margin-bottom:0;">
                <div class="card-title">Quick Actions</div>
                <div class="action-grid">
                    <a href="<%= ctx %>/sessions" class="action-card">
                        <div class="icon"><iconify-icon icon="tabler:book" width="20" height="20"></iconify-icon></div>
                        <span class="label">Browse Sessions</span>
                    </a>
                    <% if (team != null) { %>
                    <a href="<%= ctx %>/team#chat" class="action-card">
                        <div class="icon"><iconify-icon icon="tabler:messages" width="20" height="20"></iconify-icon></div>
                        <span class="label">Team Chat</span>
                    </a>
                    <a href="<%= ctx %>/project" class="action-card">
                        <div class="icon"><iconify-icon icon="tabler:bulb" width="20" height="20"></iconify-icon></div>
                        <span class="label">Impact Project</span>
                    </a>
                    <% } %>
                    <a href="<%= ctx %>/profile" class="action-card">
                        <div class="icon"><iconify-icon icon="tabler:id-badge-2" width="20" height="20"></iconify-icon></div>
                        <span class="label">My Portfolio</span>
                    </a>
                    <a href="<%= ctx %>/opportunities" class="action-card">
                        <div class="icon"><iconify-icon icon="tabler:briefcase" width="20" height="20"></iconify-icon></div>
                        <span class="label">Opportunities</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
</main>

<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
