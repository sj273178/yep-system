<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil" %>
<%--
    Quiz editor for a facilitator's session (FR10). QuestionServlet supplies:
      activity, quiz, locked (true once any participant has taken the quiz).
--%>
<%
    Activity activity = (Activity) request.getAttribute("activity");
    Quiz     quiz     = (Quiz)     request.getAttribute("quiz");
    Boolean  locked   = (Boolean)  request.getAttribute("locked");
    String ctx = request.getContextPath();
    if (activity == null) { response.sendRedirect(ctx + "/sessions"); return; }
    int max = com.yep.servlet.QuestionServlet.MAX_QUESTIONS;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quiz Questions — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <p style="margin-bottom:6px;"><a href="<%= ctx %>/sessions" style="color:rgba(255,255,255,.85);">&larr; Sessions</a></p>
    <h1>Quiz: <%= esc(activity.getTitle()) %></h1>
    <p><%= DateUtil.format(activity.getSessionDate()) %> &middot; participants take this quiz after joining the session.
       It is marked automatically and each participant has one attempt.</p>
</div></div>

<main class="main-content" id="main">
    <% if (locked) { %>
        <div class="alert alert-info" style="display:block;">
            Participants have already taken this quiz, so the questions are locked to keep marking fair.
            Use <a href="<%= ctx %>/quiz?activityId=<%= activity.getActivityId() %>">Assessments</a> to see their scores.
        </div>
    <% } else if (quiz.isEmpty()) { %>
        <div class="alert alert-warning" style="display:block;">
            This session has no quiz yet. Add about 5 questions so participants can complete the session.
        </div>
    <% } %>

    <div class="two-col" style="align-items:start;">
        <section class="card">
            <h2 class="card-title">Questions (<%= quiz.getSize() %>/<%= max %>)</h2>
            <% if (quiz.isEmpty()) { %>
                <p class="muted">No questions yet.</p>
            <% } else { %>
                <ol class="quiz-review" style="margin-left:18px;">
                <% for (Question q : quiz.getQuestions()) { %>
                    <li>
                        <strong><%= esc(q.getText()) %></strong>
                        <ul style="list-style:none;padding:0;margin:6px 0;">
                            <% for (char letter : Question.LETTERS) {
                                   boolean right = letter == q.getCorrectOption(); %>
                                <li class="small" style="<%= right ? "color:var(--primary-darker);font-weight:600;" : "" %>">
                                    <%= letter %>. <%= esc(q.getOption(letter)) %> <%= right ? "✓ correct" : "" %>
                                </li>
                            <% } %>
                        </ul>
                        <% if (!locked) { %>
                            <form action="<%= ctx %>/questions" method="POST" class="inline-form">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="activityId" value="<%= activity.getActivityId() %>">
                                <input type="hidden" name="questionId" value="<%= q.getQuestionId() %>">
                                <button type="submit" class="btn btn-danger btn-sm" data-confirm="Delete this question?">Delete</button>
                            </form>
                        <% } %>
                    </li>
                <% } %>
                </ol>
            <% } %>
        </section>

        <% if (!locked && quiz.getSize() < max) { %>
        <section class="card">
            <h2 class="card-title">Add a Question</h2>
            <form action="<%= ctx %>/questions" method="POST">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="activityId" value="<%= activity.getActivityId() %>">
                <div class="form-group">
                    <label for="questionText">Question *</label>
                    <textarea id="questionText" name="questionText" rows="2" required minlength="5" maxlength="500"
                              placeholder="e.g. Which password is the strongest?"></textarea>
                </div>
                <% for (char letter : Question.LETTERS) { %>
                    <div class="form-group">
                        <label for="option<%= letter %>">Option <%= letter %> *</label>
                        <input type="text" id="option<%= letter %>" name="option<%= letter %>" required maxlength="200">
                    </div>
                <% } %>
                <div class="form-group">
                    <label for="correctOption">Correct answer *</label>
                    <select id="correctOption" name="correctOption" required>
                        <option value="">-- Choose --</option>
                        <% for (char letter : Question.LETTERS) { %><option value="<%= letter %>">Option <%= letter %></option><% } %>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary">
                    <iconify-icon icon="tabler:plus" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Add Question
                </button>
            </form>
        </section>
        <% } %>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
