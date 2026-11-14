<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.nio.charset.StandardCharsets" %>
<%--
    Session page for a participant (wireframe "Session page", report page 26).
    Three steps to complete a session:  1. Learn  2. Join  3. Take the quiz.
    SessionServlet supplies: activity, attendedMode (null if not joined), quiz, quizResult (null if not taken).
--%>
<%
    Activity   activity     = (Activity)   request.getAttribute("activity");
    String     attendedMode = (String)     request.getAttribute("attendedMode");
    Quiz       quiz         = (Quiz)       request.getAttribute("quiz");
    Assessment quizResult   = (Assessment) request.getAttribute("quizResult");
    String ctx = request.getContextPath();
    if (activity == null) { response.sendRedirect(ctx + "/sessions"); return; }

    boolean started  = activity.hasStarted();
    boolean joined   = attendedMode != null;
    boolean hasQuiz  = quiz != null && !quiz.isEmpty();
    boolean quizDone = quizResult != null;
    boolean complete = joined && (quizDone || !hasQuiz);
    int notesKb = activity.getNotes() == null ? 0
                : Math.max(1, activity.getNotes().getBytes(StandardCharsets.UTF_8).length / 1024);
    String modeLabel = "audio".equals(attendedMode) ? "Audio only"
                     : "download".equals(attendedMode) ? "Downloaded notes" : "Video";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= esc(activity.getTitle()) %> — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <p style="margin-bottom:6px;"><a href="<%= ctx %>/sessions" style="color:rgba(255,255,255,.85);">&larr; All sessions</a></p>
    <h1><%= esc(activity.getTitle()) %></h1>
    <p><%= esc(activity.getTopic()) %> &middot; <%= DateUtil.format(activity.getSessionDate()) %> &middot; <%= activity.getDurationMins() %> min
       <% if (activity.isLowBandwidth()) { %>&middot; low-data friendly<% } %></p>
</div></div>

<main class="main-content" id="main">

    <%-- Step tracker --%>
    <ol class="steps" aria-label="Session progress">
        <li class="done"><span>1</span> Learn</li>
        <li class="<%= joined ? "done" : "current" %>"><span>2</span> Join</li>
        <li class="<%= quizDone ? "done" : joined ? "current" : "" %>"><span>3</span> Quiz</li>
    </ol>
    <% if (complete) { %>
        <div class="alert alert-success" style="display:block;">
            <strong>Session complete.</strong> It counts towards your Level Two progress
            (<%= Participant.MIN_SESSIONS %> sessions, <%= (int) Participant.PROMOTION_AVERAGE %>% average).
            <a href="<%= ctx %>/participant/dashboard.jsp">View my progress &rarr;</a>
        </div>
    <% } %>

    <div class="two-col" style="align-items:start;">

        <%-- STEP 1: learning material --%>
        <section class="card" aria-labelledby="notesTitle">
            <h2 class="card-title" id="notesTitle"><iconify-icon icon="tabler:notebook" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> 1. Learning notes</h2>
            <% if (activity.getDescription() != null) { %>
                <p class="muted" style="margin-bottom:12px;"><%= esc(activity.getDescription()) %></p>
            <% } %>
            <% if (activity.getNotes() != null) { %>
                <div class="session-notes"><%= esc(activity.getNotes()) %></div>
                <div class="row-actions" style="margin-top:14px;">
                    <a class="btn btn-outline btn-sm" href="<%= ctx %>/sessions?id=<%= activity.getActivityId() %>&amp;download=notes">
                        <iconify-icon icon="tabler:download" width="14" height="14" style="vertical-align:-2px;"></iconify-icon>
                        Download notes (<%= notesKb %> KB)
                    </a>
                    <% if (activity.getRecordingUrl() != null) { %>
                        <a class="btn btn-outline btn-sm" href="<%= esc(activity.getRecordingUrl()) %>" target="_blank" rel="noopener">
                            <iconify-icon icon="tabler:player-play" width="14" height="14" style="vertical-align:-2px;"></iconify-icon>
                            Recording
                        </a>
                    <% } %>
                </div>
            <% } else { %>
                <p class="muted">The facilitator has not added notes for this session yet.</p>
            <% } %>
        </section>

        <div>
            <%-- STEP 2: join --%>
            <section class="card" aria-labelledby="joinTitle">
                <h2 class="card-title" id="joinTitle"><iconify-icon icon="tabler:door-enter" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> 2. Join the session</h2>
                <% if (joined) { %>
                    <p><span class="badge badge-green">Joined</span> &nbsp;via <strong><%= modeLabel %></strong>
                       &middot; +<%= Participant.POINTS_PER_SESSION %> points</p>
                <% } else if (!started) { %>
                    <p class="muted">This session opens on <strong><%= DateUtil.format(activity.getSessionDate()) %></strong>.
                       You can read the notes now and join from that time.</p>
                <% } else { %>
                    <p class="small muted" style="margin-bottom:12px;">Choose how you took part. Recordings and notes count the same as attending live.</p>
                    <form action="<%= ctx %>/sessions" method="POST" class="join-options">
                        <input type="hidden" name="action" value="attend">
                        <input type="hidden" name="activityId" value="<%= activity.getActivityId() %>">
                        <button type="submit" name="mode" value="video" class="btn btn-primary btn-block">
                            <iconify-icon icon="tabler:video" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Video (uses more data)
                        </button>
                        <button type="submit" name="mode" value="audio" class="btn btn-primary btn-block" style="background:#15803d;">
                            <iconify-icon icon="tabler:headphones" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Audio only (low data)
                        </button>
                        <button type="submit" name="mode" value="download" class="btn btn-outline btn-block">
                            <iconify-icon icon="tabler:file-text" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> I read the notes
                        </button>
                    </form>
                <% } %>
            </section>

            <%-- STEP 3: quiz --%>
            <section class="card" aria-labelledby="quizTitle">
                <h2 class="card-title" id="quizTitle"><iconify-icon icon="tabler:checklist" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> 3. Quiz</h2>

                <% if (!hasQuiz) { %>
                    <p class="muted">This session has no online quiz. Your facilitator may record a participation score instead.</p>

                <% } else if (quizDone) {
                       double pct = quizResult.getScore(); %>
                    <div class="quiz-result <%= pct >= Quiz.PASS_MARK ? "pass" : "fail" %>">
                        <div class="quiz-score"><%= String.format("%.0f", pct) %>%</div>
                        <div>
                            <strong><%= Participant.computeGrade(pct) %></strong><br>
                            <span class="small"><%= esc(quizResult.getComment()) %></span>
                        </div>
                    </div>
                    <details style="margin-top:14px;">
                        <summary style="cursor:pointer;font-weight:600;">Review the correct answers</summary>
                        <ol class="quiz-review">
                            <% for (Question q : quiz.getQuestions()) { %>
                                <li><%= esc(q.getText()) %><br>
                                    <span class="small"><iconify-icon icon="tabler:check" width="13" height="13" style="color:var(--primary);vertical-align:-2px;"></iconify-icon>
                                    <%= q.getCorrectOption() %>. <%= esc(q.getOption(q.getCorrectOption())) %></span></li>
                            <% } %>
                        </ol>
                    </details>

                <% } else if (!joined) { %>
                    <p class="muted"><%= quiz.getSize() %> questions &middot; pass mark <%= (int) Quiz.PASS_MARK %>% &middot; one attempt.</p>
                    <p class="small muted" style="margin-top:6px;">Join the session first to unlock the quiz.</p>

                <% } else { %>
                    <p class="small muted" style="margin-bottom:14px;"><%= quiz.getSize() %> questions &middot; pass mark <%= (int) Quiz.PASS_MARK %>% &middot;
                        <strong>one attempt</strong> — read the notes again before you start if you need to.</p>
                    <form action="<%= ctx %>/sessions" method="POST">
                        <input type="hidden" name="action" value="takeQuiz">
                        <input type="hidden" name="activityId" value="<%= activity.getActivityId() %>">
                        <% int n = 1; for (Question q : quiz.getQuestions()) { %>
                            <fieldset class="quiz-question">
                                <legend><%= n++ %>. <%= esc(q.getText()) %></legend>
                                <% for (char letter : Question.LETTERS) {
                                       String inputId = "q" + q.getQuestionId() + letter; %>
                                    <label for="<%= inputId %>" class="quiz-option">
                                        <input type="radio" id="<%= inputId %>" name="q<%= q.getQuestionId() %>" value="<%= letter %>" required>
                                        <span><%= letter %>. <%= esc(q.getOption(letter)) %></span>
                                    </label>
                                <% } %>
                            </fieldset>
                        <% } %>
                        <button type="submit" class="btn btn-accent btn-block"
                                data-confirm="Submit your answers? You only have one attempt.">
                            <iconify-icon icon="tabler:send" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Submit answers
                        </button>
                    </form>
                <% } %>
            </section>
        </div>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
