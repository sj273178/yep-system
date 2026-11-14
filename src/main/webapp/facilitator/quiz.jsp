<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    Record quiz / participation scores (FR10). QuizServlet supplies:
      activities     — this facilitator's sessions
      activity       — the selected session (or null)
      attendees      — participants who attended it
      existingScores — scores already recorded for it
--%>
<%
    List<Activity>    activities = (List<Activity>)    request.getAttribute("activities");
    Activity          activity   = (Activity)          request.getAttribute("activity");
    List<Participant> attendees  = (List<Participant>) request.getAttribute("attendees");
    List<Assessment>  scores     = (List<Assessment>)  request.getAttribute("existingScores");
    boolean hasOnlineQuiz = Boolean.TRUE.equals(request.getAttribute("hasOnlineQuiz"));
    if (activities == null) activities = new ArrayList<>();
    if (attendees  == null) attendees  = new ArrayList<>();
    if (scores     == null) scores     = new ArrayList<>();

    Map<Integer, String> names = new HashMap<>();
    for (Participant p : attendees) names.put(p.getUserId(), p.getFullName());

    // Average per participant across this session's scores, for the attendee list
    Map<Integer, List<Assessment>> byParticipant = new HashMap<>();
    for (Assessment a : scores) byParticipant.computeIfAbsent(a.getParticipantId(), k -> new ArrayList<>()).add(a);

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Assessments — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Assessment Scores</h1>
    <p>See online quiz results for your sessions and record participation scores (0–100) for the participants who attended.</p>
</div></div>
<main class="main-content" id="main">

    <div class="card">
        <form action="<%= ctx %>/quiz" method="GET" style="display:flex;gap:10px;align-items:flex-end;flex-wrap:wrap;">
            <div class="form-group" style="flex:1;min-width:240px;margin-bottom:0;">
                <label for="activityPick">Session</label>
                <select id="activityPick" name="activityId" required onchange="this.form.submit()">
                    <option value="">-- Choose one of your sessions --</option>
                    <% for (Activity a : activities) { %>
                        <option value="<%= a.getActivityId() %>"
                            <%= (activity != null && activity.getActivityId() == a.getActivityId()) ? "selected" : "" %>>
                            <%= esc(a.getTitle()) %> (<%= DateUtil.format(a.getSessionDate()) %>)
                        </option>
                    <% } %>
                </select>
            </div>
            <noscript><button type="submit" class="btn btn-outline">Open</button></noscript>
        </form>
        <% if (activities.isEmpty()) { %>
            <p class="small muted" style="margin-top:10px;">You have not created any sessions yet.
               <a href="<%= ctx %>/sessions?action=create">Create one</a>.</p>
        <% } %>
    </div>

    <% if (activity != null) { %>
    <div class="two-col">
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:clipboard-check" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Record a Score</div>
            <% if (attendees.isEmpty()) { %>
                <p class="muted">Nobody has attended "<%= esc(activity.getTitle()) %>" yet, so there is no one to score.</p>
            <% } else { %>
            <form action="<%= ctx %>/quiz" method="POST">
                <input type="hidden" name="activityId" value="<%= activity.getActivityId() %>">
                <div class="form-group">
                    <label for="participantId">Participant *</label>
                    <select id="participantId" name="participantId" required>
                        <option value="">-- Choose participant --</option>
                        <% for (Participant p : attendees) { %>
                            <option value="<%= p.getUserId() %>"><%= esc(p.getFullName()) %> (<%= esc(p.getCountry()) %>)</option>
                        <% } %>
                    </select>
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label for="score">Score (0–100) *</label>
                        <input type="number" id="score" name="score" required min="0" max="100" step="0.5" placeholder="e.g. 78">
                    </div>
                    <div class="form-group">
                        <label for="type">Type *</label>
                        <select id="type" name="type" required>
                            <% if (!hasOnlineQuiz) { %><option value="quiz">Quiz</option><% } %>
                            <option value="participation">Participation</option>
                        </select>
                        <% if (hasOnlineQuiz) { %>
                            <span class="form-hint">Quiz scores for this session come from the online quiz (marked automatically).</span>
                        <% } %>
                    </div>
                </div>
                <div class="form-group">
                    <label for="comment">Comment (optional)</label>
                    <textarea id="comment" name="comment" rows="2" maxlength="1000" placeholder="Feedback for the participant..."></textarea>
                </div>
                <p class="form-hint" style="margin-bottom:12px;">Entering a score again for the same participant and type replaces the old one.</p>
                <button type="submit" class="btn btn-primary">
                    <iconify-icon icon="tabler:device-floppy" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Save Score
                </button>
            </form>
            <% } %>
        </div>

        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:list-numbers" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Attendees &amp; Scores (<%= attendees.size() %>)</div>
            <% if (attendees.isEmpty()) { %>
                <p class="muted">No attendees yet.</p>
            <% } else { %>
            <div class="table-wrap">
                <table>
                    <thead><tr><th scope="col">Participant</th><th scope="col">Type</th><th scope="col">Score</th><th scope="col">Grade</th></tr></thead>
                    <tbody>
                    <% for (Participant p : attendees) {
                           List<Assessment> mine = byParticipant.getOrDefault(p.getUserId(), Collections.emptyList());
                           if (mine.isEmpty()) { %>
                        <tr><td><%= esc(p.getFullName()) %></td><td colspan="3" class="muted small">Not scored yet</td></tr>
                    <%     } else { for (Assessment a : mine) { %>
                        <tr>
                            <td><%= esc(p.getFullName()) %>
                                <% if (a.getComment() != null) { %><div class="small muted"><%= esc(a.getComment()) %></div><% } %>
                            </td>
                            <td><%= "quiz".equals(a.getType()) && a.getComment() != null && a.getComment().startsWith("Online quiz") ? "Online quiz" : esc(a.getType()) %></td>
                            <td><strong><%= String.format("%.1f", a.getScore()) %></strong></td>
                            <td><%= Participant.computeGrade(a.getScore()) %></td>
                        </tr>
                    <%     } }
                       } %>
                    </tbody>
                </table>
            </div>
            <% } %>
        </div>
    </div>
    <% } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
