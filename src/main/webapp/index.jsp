<%@ page contentType="text/html;charset=UTF-8" %>
<%--
    Public home page. Explains the YEP journey and links to the public
    features: register, sign in, opportunities (FR24), talent directory (FR23)
    and certificate verification (FR20).
--%>
<% String ctx = request.getContextPath(); %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Youth Empowerment Project — free digital skills and virtual exchange for young people in East Africa.">
    <title>YEP — Youth Empowerment Project</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>

<main id="main">
    <section class="hero">
        <div class="hero-eyebrow"><iconify-icon icon="tabler:world" width="14" height="14"></iconify-icon> For youth aged 18–35 in the 8 EAC countries</div>
        <h1>Learn digital skills. <span>Solve real problems</span> together.</h1>
        <p>YEP is a free online programme: join short sessions, pass quizzes, team up with young people from
           other countries and build an Impact Project with a mentor.</p>
        <% if (navUser != null) { %>
        <div class="hero-actions">
            <a href="<%= ctx + navUser.getDashboardMenu() %>" class="btn btn-accent">
                <iconify-icon icon="tabler:layout-dashboard" width="18" height="18"></iconify-icon> Go to my dashboard</a>
        </div>
        <% } %>
    </section>

    <div class="hero-stats">
        <div><strong>8</strong><span>EAC countries</span></div>
        <div><strong>2</strong><span>Levels</span></div>
        <div><strong>3–5</strong><span>Youth per team</span></div>
        <div><strong>100%</strong><span>Free</span></div>
    </div>

    <section class="home-section">
        <h2>Your YEP journey</h2>
        <p class="lead">Four simple steps from your first session to a verified certificate.</p>
        <div class="journey">
            <div class="card">
                <div class="icon-circle"><iconify-icon icon="tabler:book" width="22" height="22"></iconify-icon></div>
                <h3>Learn (Level One)</h3>
                <p>Join sessions by video, audio only or downloadable notes — made for low data.</p>
            </div>
            <div class="card">
                <div class="icon-circle"><iconify-icon icon="tabler:clipboard-check" width="22" height="22"></iconify-icon></div>
                <h3>Take quizzes</h3>
                <p>Complete 3 sessions with an average of 60% or more to qualify for Level Two.</p>
            </div>
            <div class="card">
                <div class="icon-circle"><iconify-icon icon="tabler:users-group" width="22" height="22"></iconify-icon></div>
                <h3>Team up (Level Two)</h3>
                <p>Work in a mixed-country team with a mentor and chat in your team space.</p>
            </div>
            <div class="card">
                <div class="icon-circle"><iconify-icon icon="tabler:certificate" width="22" height="22"></iconify-icon></div>
                <h3>Get certified</h3>
                <p>Submit your Impact Project and earn certificates that employers can verify.</p>
            </div>
        </div>
    </section>

    <section class="home-section">
        <h2>For employers and partners</h2>
        <p class="lead">No account needed.</p>
        <div class="three-col">
            <a class="card feature" href="<%= ctx %>/talent" style="color:inherit;text-decoration:none;">
                <div class="icon-circle"><iconify-icon icon="tabler:id-badge-2" width="22" height="22"></iconify-icon></div>
                <h3>Talent directory</h3>
                <p>Browse skills portfolios that participants chose to share.</p>
            </a>
            <a class="card feature" href="<%= ctx %>/opportunities" style="color:inherit;text-decoration:none;">
                <div class="icon-circle"><iconify-icon icon="tabler:briefcase" width="22" height="22"></iconify-icon></div>
                <h3>Opportunities</h3>
                <p>Internships and team challenges offered by partner organisations.</p>
            </a>
            <a class="card feature" href="<%= ctx %>/verify" style="color:inherit;text-decoration:none;">
                <div class="icon-circle"><iconify-icon icon="tabler:rosette-discount-check" width="22" height="22"></iconify-icon></div>
                <h3>Verify a certificate</h3>
                <p>Type the code printed on a YEP certificate to check it is genuine.</p>
            </a>
        </div>
    </section>

    <% if (navUser == null) { %>
    <section class="cta-band">
        <div>
            <h2>Ready to start?</h2>
            <p>Registration takes less than 5 minutes.</p>
        </div>
        <a href="<%= ctx %>/register" class="btn btn-accent btn-lg">Create my free account</a>
    </section>
    <% } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
