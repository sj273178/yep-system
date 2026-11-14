<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%-- Team formation and mentor assignment (FR13, FR14). AdminServlet supplies all data. --%>
<%
    List<Team>        teams       = (List<Team>)        request.getAttribute("teams");
    List<Mentor>      mentors     = (List<Mentor>)      request.getAttribute("mentors");
    List<Participant> unassigned  = (List<Participant>) request.getAttribute("unassigned");
    Map<Integer, List<Participant>> membersMap = (Map<Integer, List<Participant>>) request.getAttribute("membersMap");
    Map<Integer, String>  mentorNames = (Map<Integer, String>)  request.getAttribute("mentorNames");
    Map<Integer, Integer> mentorLoad  = (Map<Integer, Integer>) request.getAttribute("mentorLoad");
    if (teams == null) { response.sendRedirect(request.getContextPath() + "/admin?page=teams"); return; }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Team Management — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Team Management</h1>
    <p>Form cross-country Level Two teams of <%= Team.MIN_SIZE %>–<%= Team.MAX_SIZE %> and assign mentors (max 3 teams each).</p>
</div></div>
<main class="main-content" id="main">
    <div class="two-col">
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:wand" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Auto-Form Teams</div>
            <p style="margin-bottom:10px;">
                <strong><%= unassigned.size() %></strong> Level Two participant(s) waiting for a team.
                The system spreads each country across the teams so every team is as mixed as possible.
            </p>
            <% if (!unassigned.isEmpty()) { %>
                <div class="pill-list" style="margin-bottom:14px;">
                    <% for (Participant p : unassigned) { %>
                        <span class="pill"><%= esc(p.getFullName()) %> &middot; <%= esc(p.getCountry()) %></span>
                    <% } %>
                </div>
            <% } %>
            <form action="<%= ctx %>/admin" method="POST">
                <input type="hidden" name="action" value="formTeams">
                <div class="form-group">
                    <label for="focusArea">Focus area for the new teams</label>
                    <select id="focusArea" name="focusArea" required>
                        <% for (String area : Team.FOCUS_AREAS) { %>
                            <option value="<%= area %>"><%= Team.focusLabel(area) %></option>
                        <% } %>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary" <%= unassigned.size() < Team.MIN_SIZE ? "disabled" : "" %>
                        data-confirm="Form teams from the <%= unassigned.size() %> waiting participants?">
                    <iconify-icon icon="tabler:users-plus" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Form Teams Now
                </button>
                <% if (unassigned.size() < Team.MIN_SIZE) { %>
                    <p class="form-hint">At least <%= Team.MIN_SIZE %> waiting participants are needed. Promote more on the Promote page.</p>
                <% } %>
            </form>
        </div>

        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:user-star" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Assign Mentor to Team</div>
            <% if (teams.isEmpty() || mentors.isEmpty()) { %>
                <p class="muted"><%= teams.isEmpty() ? "Form a team first." : "No active mentors. Create one on the Users page." %></p>
            <% } else { %>
            <form action="<%= ctx %>/admin" method="POST">
                <input type="hidden" name="action" value="assignMentor">
                <div class="form-group">
                    <label for="teamId">Team</label>
                    <select id="teamId" name="teamId" required>
                        <option value="">-- Choose team --</option>
                        <% for (Team t : teams) { %>
                            <option value="<%= t.getTeamId() %>">
                                <%= esc(t.getName()) %> — <%= t.getMentorId() == null ? "no mentor" : "mentor: " + esc(mentorNames.getOrDefault(t.getMentorId(), "#" + t.getMentorId())) %>
                            </option>
                        <% } %>
                    </select>
                </div>
                <div class="form-group">
                    <label for="mentorId">Mentor</label>
                    <select id="mentorId" name="mentorId" required>
                        <option value="">-- Choose mentor --</option>
                        <% for (Mentor m : mentors) {
                               int load = mentorLoad.getOrDefault(m.getUserId(), 0);
                               boolean full = load >= m.getMaxTeams(); %>
                            <option value="<%= m.getUserId() %>" <%= full ? "disabled" : "" %>>
                                <%= esc(m.getFullName()) %> (<%= esc(m.getExpertise()) %>) — <%= load %>/<%= m.getMaxTeams() %> teams<%= full ? " — full" : "" %>
                            </option>
                        <% } %>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary">
                    <iconify-icon icon="tabler:link" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Assign Mentor
                </button>
            </form>
            <% } %>
        </div>
    </div>

    <div class="card">
        <div class="card-title"><iconify-icon icon="tabler:users-group" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> All Teams (<%= teams.size() %>)</div>
        <% if (teams.isEmpty()) { %>
            <p class="muted">No teams yet.</p>
        <% } else { %>
            <div class="table-wrap">
                <table>
                    <thead><tr><th scope="col">Team</th><th scope="col">Focus</th><th scope="col">Members</th><th scope="col">Mentor</th><th scope="col">Created</th><th scope="col"></th></tr></thead>
                    <tbody>
                    <% for (Team t : teams) { %>
                        <tr>
                            <td><strong><%= esc(t.getName()) %></strong></td>
                            <td><span class="badge badge-blue"><%= esc(t.getFocusLabel()) %></span></td>
                            <td>
                                <div class="pill-list">
                                <% for (Participant m : membersMap.getOrDefault(t.getTeamId(), Collections.emptyList())) { %>
                                    <span class="pill"><%= esc(m.getFullName()) %> &middot; <%= esc(m.getCountry()) %></span>
                                <% } %>
                                </div>
                            </td>
                            <td><%= t.getMentorId() != null ? esc(mentorNames.getOrDefault(t.getMentorId(), "Inactive mentor")) : "<span class=\"badge badge-gold\">None</span>" %></td>
                            <td class="small" style="white-space:nowrap;"><%= DateUtil.format(t.getCreatedAt().toLocalDate()) %></td>
                            <td><a href="<%= ctx %>/team?teamId=<%= t.getTeamId() %>" class="btn btn-outline btn-sm">View</a></td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
