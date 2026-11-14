<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    Partner opportunities (FR24): internships and team challenges.
    Anyone can browse. The admin posts and removes them on behalf of partners.
--%>
<%
    List<Opportunity> opportunities = (List<Opportunity>) request.getAttribute("opportunities");
    if (opportunities == null) { response.sendRedirect(request.getContextPath() + "/opportunities"); return; }
    User viewer = (User) session.getAttribute("loggedInUser");
    boolean isAdmin = viewer instanceof Admin;
    String ctx = request.getContextPath();
    int open = 0;
    for (Opportunity o : opportunities) if (o.isOpen()) open++;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Opportunities — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>

<div class="page-header"><div class="container">
    <h1>Opportunities from our Partners</h1>
    <p><%= open %> open internship(s) and team challenge(s) for YEP participants across East Africa</p>
</div></div>

<main class="main-content" id="main">

    <% if (isAdmin) { %>
    <details class="card" <%= opportunities.isEmpty() ? "open" : "" %>>
        <summary class="card-title" style="cursor:pointer;margin-bottom:0;">
            <iconify-icon icon="tabler:circle-plus" width="18" height="18"></iconify-icon> Post a new opportunity for a partner
        </summary>
        <form method="POST" action="<%= ctx %>/opportunities" style="margin-top:16px;">
            <input type="hidden" name="action" value="create">
            <div class="form-grid">
                <div class="form-group"><label for="title">Title</label>
                    <input type="text" id="title" name="title" required maxlength="200"></div>
                <div class="form-group"><label for="organisation">Partner organisation</label>
                    <input type="text" id="organisation" name="organisation" required maxlength="150"></div>
                <div class="form-group"><label for="type">Type</label>
                    <select id="type" name="type" required>
                        <option value="internship">Internship (for individuals)</option>
                        <option value="challenge">Team Challenge (for Level Two teams)</option>
                    </select></div>
                <div class="form-group"><label for="deadline">Deadline</label>
                    <input type="date" id="deadline" name="deadline" required></div>
                <div class="form-group"><label for="country">Country</label>
                    <select id="country" name="country">
                        <option value="">All EAC countries</option>
                        <% for (String c : User.EAC_COUNTRIES) { %><option><%= esc(c) %></option><% } %>
                    </select></div>
                <div class="form-group"><label for="applyLink">Application link (optional)</label>
                    <input type="text" id="applyLink" name="applyLink" maxlength="300" placeholder="https://"></div>
            </div>
            <div class="form-group"><label for="description">Description</label>
                <textarea id="description" name="description" required minlength="20" rows="3"></textarea></div>
            <button class="btn btn-primary"><iconify-icon icon="tabler:send" width="16" height="16"></iconify-icon> Post Opportunity</button>
        </form>
    </details>
    <% } %>

    <% if (opportunities.isEmpty()) { %>
        <div class="card empty-state"><p class="muted">No opportunities have been posted yet. Please check again soon.</p></div>
    <% } else { %>
    <div class="card-grid">
        <% for (Opportunity o : opportunities) { %>
        <article class="card<%= o.isOpen() ? "" : " closed" %>">
            <div style="display:flex;justify-content:space-between;gap:8px;align-items:flex-start;margin-bottom:6px;">
                <span class="badge <%= o.isChallenge() ? "badge-purple" : "badge-blue" %>">
                    <iconify-icon icon="tabler:<%= o.isChallenge() ? "trophy" : "briefcase" %>" width="12" height="12"></iconify-icon>&nbsp;<%= o.getTypeLabel() %>
                </span>
                <span class="badge <%= o.isOpen() ? "badge-green" : "badge-grey" %>"><%= o.isOpen() ? "Open" : "Closed" %></span>
            </div>
            <h3 style="margin-bottom:2px;"><%= esc(o.getTitle()) %></h3>
            <div class="opp-org"><%= esc(o.getOrganisation()) %></div>
            <div class="opp-meta">
                <span><iconify-icon icon="tabler:map-pin" width="14" height="14"></iconify-icon><%= esc(o.getCountryLabel()) %></span>
                <span><iconify-icon icon="tabler:calendar-due" width="14" height="14"></iconify-icon>Apply by <%= DateUtil.format(o.getDeadline()) %></span>
            </div>
            <p class="small" style="color:var(--text-secondary);white-space:pre-line;"><%= esc(o.getDescription()) %></p>
            <div class="card-foot">
                <% if (o.getApplyLink() != null && o.isOpen()) { %>
                    <a class="btn btn-sm btn-primary" href="<%= esc(o.getApplyLink()) %>" target="_blank" rel="noopener noreferrer">
                        Apply <iconify-icon icon="tabler:external-link" width="14" height="14"></iconify-icon></a>
                <% } else if (o.isOpen()) { %>
                    <span class="small muted">Ask your facilitator or mentor how to apply.</span>
                <% } %>
                <% if (isAdmin) { %>
                    <form method="POST" action="<%= ctx %>/opportunities" class="inline-form" style="margin-left:auto;"
                          onsubmit="return confirm('Remove this opportunity?');">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="opportunityId" value="<%= o.getOpportunityId() %>">
                        <button class="btn btn-sm btn-ghost" style="color:var(--danger);">Remove</button>
                    </form>
                <% } %>
            </div>
        </article>
        <% } %>
    </div>
    <% } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
