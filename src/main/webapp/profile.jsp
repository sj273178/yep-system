<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    My Profile — for every role (ProfileServlet).
      * "My data": everything YEP stores about the user (Data Protection and Privacy Act 2019)
      * Participants: skills portfolio with a "show to employers" switch (FR23)
      * Change password, and (participants) delete my personal data
--%>
<%
    User user = (User) session.getAttribute("loggedInUser");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    Participant p = (user instanceof Participant) ? (Participant) user : null;
    List<Certificate> certs = (List<Certificate>) request.getAttribute("certificates");
    if (certs == null) certs = new ArrayList<>();
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>

<div class="page-header"><div class="container" style="display:flex;align-items:center;gap:16px;">
    <div class="nav-avatar" style="width:56px;height:56px;font-size:1.4rem;background:rgba(255,255,255,.2);" aria-hidden="true">
        <%= esc(user.getFullName().substring(0, 1).toUpperCase()) %>
    </div>
    <div>
        <h1><%= esc(user.getFullName()) %></h1>
        <p><%= esc(user.getRole().charAt(0) + user.getRole().substring(1).toLowerCase()) %>
           <% if (p != null) { %> &middot; Level <%= p.getVeLevel() %> &middot; <%= p.getPoints() %> points<% } %>
           &middot; member since <%= DateUtil.format(user.getCreatedAt().toLocalDate()) %></p>
    </div>
</div></div>

<main class="main-content" id="main">
<div class="two-col">

    <%-- ============ LEFT: edit profile / portfolio ============ --%>
    <div>
        <div class="card">
            <div class="card-title">
                <iconify-icon icon="tabler:<%= p != null ? "id-badge-2" : "user-edit" %>" width="18" height="18"></iconify-icon>
                <%= p != null ? "My Skills Portfolio" : "My Details" %>
            </div>
            <form method="POST" action="<%= ctx %>/profile">
                <input type="hidden" name="action" value="saveProfile">
                <div class="form-group">
                    <label for="phone">Phone (for SMS notifications)</label>
                    <input type="tel" id="phone" name="phone" autocomplete="tel" value="<%= esc(user.getPhone()) %>" placeholder="+256700000000">
                </div>

                <% if (p != null) { %>
                <div class="form-group">
                    <label for="district">District / City</label>
                    <input type="text" id="district" name="district" maxlength="100" value="<%= esc(p.getDistrict()) %>">
                </div>
                <div class="form-group">
                    <label for="bio">Short bio</label>
                    <textarea id="bio" name="bio" maxlength="500" rows="3"
                              placeholder="e.g. Agriculture student who loves solving problems with simple digital tools."><%= esc(p.getBio()) %></textarea>
                </div>
                <div class="form-group">
                    <label for="skills">Skills (separate with commas)</label>
                    <input type="text" id="skills" name="skills" maxlength="300" value="<%= esc(p.getSkills()) %>"
                           placeholder="Excel, Canva, Public speaking, Python basics">
                </div>
                <div class="form-group">
                    <label for="portfolioLink">Link to my work (optional)</label>
                    <input type="text" id="portfolioLink" name="portfolioLink" maxlength="300" value="<%= esc(p.getPortfolioLink()) %>"
                           placeholder="https://sites.google.com/view/your-name">
                </div>
                <label class="checkbox-row" style="margin-bottom:18px;">
                    <input type="checkbox" name="portfolioPublic" <%= p.isPortfolioPublic() ? "checked" : "" %>>
                    <span>
                        <strong>Show my portfolio to partner employers</strong><br>
                        <span class="small muted">Only your name, country, level, bio, skills, link and certificates are shown on the
                        public <a href="<%= ctx %>/talent">Talent page</a> — never your email, phone or age. You can switch this off at any time.</span>
                    </span>
                </label>
                <% } %>

                <button class="btn btn-primary">
                    <iconify-icon icon="tabler:device-floppy" width="16" height="16"></iconify-icon> Save
                </button>
                <% if (p != null && p.isPortfolioPublic()) { %>
                    <span class="badge badge-green" style="margin-left:8px;">Visible to employers</span>
                <% } %>
            </form>
        </div>

        <% if (p != null) { %>
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:certificate" width="18" height="18"></iconify-icon> My Certificates</div>
            <% if (certs.isEmpty()) { %>
                <p class="muted small">No certificates yet. Complete 3 sessions with an average of 50% or more to earn Level One.</p>
            <% } else { for (Certificate c : certs) { %>
                <div class="todo-item">
                    <span><strong><%= esc(c.getTypeLabel()) %></strong><br>
                        <code class="small"><%= esc(c.getVerificationCode()) %></code>
                        <span class="small muted">&middot; <%= DateUtil.format(c.getIssuedDate()) %></span></span>
                    <a class="btn btn-sm btn-outline" href="<%= ctx %>/certificate?code=<%= esc(c.getVerificationCode()) %>">View</a>
                </div>
            <% } } %>
        </div>
        <% } %>
    </div>

    <%-- ============ RIGHT: my data, password, delete ============ --%>
    <div>
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:shield-lock" width="18" height="18"></iconify-icon> My Data</div>
            <p class="small muted" style="margin-bottom:8px;">
                This is everything YEP stores about you (Uganda Data Protection and Privacy Act 2019).
            </p>
            <dl class="data-list">
                <div><dt>Full name</dt><dd><%= esc(user.getFullName()) %></dd></div>
                <div><dt>Email</dt><dd><%= esc(user.getEmail()) %></dd></div>
                <div><dt>Phone</dt><dd><%= user.getPhone() == null ? "—" : esc(user.getPhone()) %></dd></div>
                <div><dt>Country</dt><dd><%= esc(user.getCountry()) %></dd></div>
                <% if (p != null) { %>
                <div><dt>Date of birth</dt><dd><%= DateUtil.format(p.getDateOfBirth()) %> (age <%= p.getAge() %>)</dd></div>
                <div><dt>Gender</dt><dd><%= esc(p.getGender()) %></dd></div>
                <div><dt>District</dt><dd><%= p.getDistrict() == null ? "—" : esc(p.getDistrict()) %></dd></div>
                <div><dt>Education</dt><dd><%= p.getEducationLevel() == null ? "—" : esc(p.getEducationLevel()) %></dd></div>
                <div><dt>Level / points</dt><dd>Level <%= p.getVeLevel() %> &middot; <%= p.getPoints() %> pts</dd></div>
                <% } %>
                <div><dt>Consent to data processing</dt><dd><%= user.isConsentGiven() ? "Given" : "Not recorded" %></dd></div>
                <div><dt>Password</dt><dd>Stored only as a BCrypt hash</dd></div>
            </dl>
        </div>

        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:lock" width="18" height="18"></iconify-icon> Change Password</div>
            <form method="POST" action="<%= ctx %>/profile">
                <input type="hidden" name="action" value="changePassword">
                <div class="form-group">
                    <label for="current">Current password</label>
                    <input type="password" id="current" name="current" required autocomplete="current-password">
                </div>
                <div class="form-grid">
                    <div class="form-group">
                        <label for="password">New password</label>
                        <input type="password" id="password" name="password" required minlength="8" autocomplete="new-password">
                    </div>
                    <div class="form-group">
                        <label for="confirm">Confirm</label>
                        <input type="password" id="confirm" name="confirm" required minlength="8" autocomplete="new-password">
                    </div>
                </div>
                <button class="btn btn-outline">Update Password</button>
            </form>
        </div>

        <% if (p != null) { %>
        <div class="card danger-zone">
            <div class="card-title"><iconify-icon icon="tabler:trash" width="18" height="18"></iconify-icon> Delete My Data</div>
            <p class="small" style="margin-bottom:12px;">
                Your name, email, phone and portfolio will be erased and your account closed. Your anonymous scores stay
                in programme statistics. <strong>This cannot be undone.</strong>
            </p>
            <form method="POST" action="<%= ctx %>/profile"
                  onsubmit="return confirm('Are you sure? Your personal data will be erased and you will be signed out.');">
                <input type="hidden" name="action" value="deleteAccount">
                <div class="form-group">
                    <label for="confirmPassword">Type your password to confirm</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" required autocomplete="current-password">
                </div>
                <button class="btn btn-danger">Delete my data</button>
            </form>
        </div>
        <% } %>
    </div>
</div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
