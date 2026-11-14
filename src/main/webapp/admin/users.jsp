<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%-- User management (FR22): activate / deactivate, unlock, create staff accounts. --%>
<%
    User admin = (User) session.getAttribute("loggedInUser");
    List<User> users = (List<User>) request.getAttribute("users");
    if (users == null) { response.sendRedirect(request.getContextPath() + "/admin?page=users"); return; }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Users — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>User Management</h1>
    <p>Activate or deactivate accounts, unlock locked accounts and create staff accounts.</p>
</div></div>
<main class="main-content" id="main">

    <details class="card" <%= users.size() <= 3 ? "open" : "" %>>
        <summary class="card-title" style="cursor:pointer;margin-bottom:0;">
            <iconify-icon icon="tabler:user-plus" width="18" height="18" style="vertical-align:-3px;"></iconify-icon>
            Create Staff Account (Facilitator or Mentor)
        </summary>
        <form action="<%= ctx %>/admin" method="POST" style="margin-top:16px;">
            <input type="hidden" name="action" value="createStaff">
            <div class="form-grid">
                <div class="form-group">
                    <label for="role">Role *</label>
                    <select id="role" name="role" required onchange="document.getElementById('extraLabel').textContent =
                        this.value === 'MENTOR' ? 'Area of expertise' : 'Organisation';">
                        <option value="FACILITATOR">Facilitator</option>
                        <option value="MENTOR">Mentor</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="fullName">Full Name *</label>
                    <input type="text" id="fullName" name="fullName" required minlength="3" maxlength="100">
                </div>
                <div class="form-group">
                    <label for="email">Email *</label>
                    <input type="email" id="email" name="email" required maxlength="150">
                </div>
                <div class="form-group">
                    <label for="phone">Phone</label>
                    <input type="tel" id="phone" name="phone" placeholder="+256 700 000 000">
                </div>
                <div class="form-group">
                    <label for="country">Country *</label>
                    <select id="country" name="country" required>
                        <% for (String c : User.EAC_COUNTRIES) { %><option><%= c %></option><% } %>
                    </select>
                </div>
                <div class="form-group">
                    <label for="extra" id="extraLabel">Organisation</label>
                    <input type="text" id="extra" name="extra" maxlength="150">
                </div>
                <div class="form-group">
                    <label for="password">Temporary Password *</label>
                    <input type="text" id="password" name="password" required minlength="8" autocomplete="off"
                           placeholder="8+ characters, letters and numbers">
                    <span class="form-hint">Give this to the staff member; they sign in with it.</span>
                </div>
            </div>
            <button type="submit" class="btn btn-primary">Create Account</button>
        </form>
    </details>

    <div class="card" style="padding:0;overflow:hidden;">
        <div class="table-wrap" style="border:none;border-radius:0;">
            <table>
                <thead><tr>
                    <th scope="col">ID</th><th scope="col">Name</th><th scope="col">Email</th><th scope="col">Role</th>
                    <th scope="col">Country</th><th scope="col">Joined</th><th scope="col">Status</th><th scope="col">Actions</th>
                </tr></thead>
                <tbody>
                <% for (User u : users) {
                       boolean self = u.getUserId() == admin.getUserId(); %>
                    <tr>
                        <td class="small muted">#<%= u.getUserId() %></td>
                        <td>
                            <div style="display:flex;align-items:center;gap:10px;">
                                <div style="width:32px;height:32px;border-radius:50%;background:var(--primary-light);color:var(--primary-darker);
                                            display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.8rem;flex-shrink:0;" aria-hidden="true">
                                    <%= esc(u.getFullName().substring(0, 1).toUpperCase()) %>
                                </div>
                                <span style="font-weight:600;"><%= esc(u.getFullName()) %></span>
                                <% if (u instanceof Participant) { %><span class="badge badge-grey">L<%= ((Participant) u).getVeLevel() %></span><% } %>
                            </div>
                        </td>
                        <td style="color:var(--text-secondary);"><%= esc(u.getEmail()) %></td>
                        <td><span class="badge <%= "ADMIN".equals(u.getRole()) ? "badge-purple" :
                            "FACILITATOR".equals(u.getRole()) ? "badge-blue" :
                            "MENTOR".equals(u.getRole()) ? "badge-gold" : "badge-grey" %>"><%= u.getRole() %></span></td>
                        <td><%= esc(u.getCountry()) %></td>
                        <td class="small" style="white-space:nowrap;"><%= DateUtil.format(u.getCreatedAt().toLocalDate()) %></td>
                        <td>
                            <span class="badge <%= u.isActive() ? "badge-green" : "badge-red" %>"><%= u.isActive() ? "Active" : "Inactive" %></span>
                            <% if (u.isLocked()) { %><span class="badge badge-red">Locked</span><% } %>
                        </td>
                        <td>
                            <div class="row-actions">
                                <% if (!self) { %>
                                <form action="<%= ctx %>/admin" method="POST" class="inline-form">
                                    <input type="hidden" name="action" value="toggleActive">
                                    <input type="hidden" name="userId" value="<%= u.getUserId() %>">
                                    <input type="hidden" name="active" value="<%= !u.isActive() %>">
                                    <button type="submit" class="btn btn-sm <%= u.isActive() ? "btn-danger" : "btn-primary" %>"
                                        <%= u.isActive() ? "data-confirm=\"Deactivate " + esc(u.getFullName()) + "? They will be signed out and unable to log in.\"" : "" %>>
                                        <%= u.isActive() ? "Deactivate" : "Activate" %>
                                    </button>
                                </form>
                                <% } else { %>
                                    <span class="small muted">You</span>
                                <% } %>
                                <% if (u.isLocked()) { %>
                                <form action="<%= ctx %>/admin" method="POST" class="inline-form">
                                    <input type="hidden" name="action" value="unlock">
                                    <input type="hidden" name="userId" value="<%= u.getUserId() %>">
                                    <button type="submit" class="btn btn-sm btn-outline">Unlock</button>
                                </form>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
