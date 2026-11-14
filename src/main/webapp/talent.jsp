<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,java.util.*" %>
<%--
    Talent directory (FR23): skills portfolios that participants CHOSE to
    share with partner employers. No login needed. Only safe fields are shown.
--%>
<%
    List<Participant> people = (List<Participant>) request.getAttribute("people");
    if (people == null) { response.sendRedirect(request.getContextPath() + "/talent"); return; }
    Map<Integer, List<Certificate>> certificates = (Map<Integer, List<Certificate>>) request.getAttribute("certificates");
    User viewer = (User) session.getAttribute("loggedInUser");
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Talent Directory — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>

<div class="page-header"><div class="container">
    <h1>YEP Talent Directory</h1>
    <p>Young people from East Africa with verified digital skills &mdash; for partner employers and universities</p>
</div></div>

<main class="main-content" id="main">
    <div class="alert alert-info" style="margin-bottom:20px;">
        Participants appear here only if they switched on "Show my portfolio" in their profile.
        Click a certificate code to check that it is genuine.
        <% if (viewer instanceof Participant) { %>
            <a href="<%= ctx %>/profile" style="margin-left:4px;font-weight:600;">Edit my portfolio &rarr;</a>
        <% } %>
    </div>

    <% if (people.isEmpty()) { %>
        <div class="card empty-state">
            <iconify-icon icon="tabler:id-badge-2" width="40" height="40" style="color:var(--text-muted);margin-bottom:10px;"></iconify-icon>
            <p><strong>No public portfolios yet.</strong></p>
            <p class="muted small" style="margin-top:4px;">
                Participants appear here after they add their skills in <em>My Profile</em>
                and tick <em>"Show my portfolio to partner employers"</em>.
            </p>
            <% if (viewer instanceof Participant) { %>
                <a href="<%= ctx %>/profile" class="btn btn-primary btn-sm" style="margin-top:14px;">Create my portfolio</a>
            <% } %>
        </div>
    <% } else { %>
    <div class="card-grid">
        <% for (Participant p : people) { List<Certificate> certs = certificates.get(p.getUserId()); %>
        <article class="card">
            <div class="person-head">
                <div class="nav-avatar" aria-hidden="true"><%= esc(p.getFullName().substring(0, 1).toUpperCase()) %></div>
                <div>
                    <h3 style="margin:0;"><%= esc(p.getFullName()) %></h3>
                    <div class="small muted">
                        <iconify-icon icon="tabler:map-pin" width="13" height="13"></iconify-icon> <%= esc(p.getCountry()) %>
                        &middot; <span class="badge <%= p.getVeLevel() == 2 ? "badge-gold" : "badge-green" %>" style="padding:1px 8px;">Level <%= p.getVeLevel() %></span>
                    </div>
                </div>
            </div>
            <% if (p.getBio() != null) { %>
                <p class="small" style="color:var(--text-secondary);"><%= esc(p.getBio()) %></p>
            <% } %>
            <% if (!p.getSkillList().isEmpty()) { %>
                <div class="tag-list"><% for (String skill : p.getSkillList()) { %><span class="tag"><%= esc(skill) %></span><% } %></div>
            <% } %>
            <div class="card-foot">
                <% if (certs != null) for (Certificate c : certs) { %>
                    <a class="badge badge-gold" href="<%= ctx %>/verify?code=<%= esc(c.getVerificationCode()) %>"
                       title="<%= esc(c.getTypeLabel()) %> — click to verify">
                        <iconify-icon icon="tabler:rosette-discount-check" width="13" height="13"></iconify-icon>&nbsp;<%= esc(c.getVerificationCode()) %>
                    </a>
                <% } %>
                <% if (p.getPortfolioLink() != null) { %>
                    <a class="btn btn-sm btn-outline" style="margin-left:auto;" href="<%= esc(p.getPortfolioLink()) %>"
                       target="_blank" rel="noopener noreferrer">Portfolio <iconify-icon icon="tabler:external-link" width="13" height="13"></iconify-icon></a>
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
