<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,java.util.*" %>
<%-- Level Two promotion (FR12). AdminServlet supplies the eligible participants with their figures. --%>
<%
    List<ParticipantProgress> eligible = (List<ParticipantProgress>) request.getAttribute("eligible");
    if (eligible == null) { response.sendRedirect(request.getContextPath() + "/admin?page=promote"); return; }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Promote to Level Two — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Level Two Promotion</h1>
    <p>Rule: at least <%= Participant.MIN_SESSIONS %> sessions attended and an average score of
       <%= (int) Participant.PROMOTION_AVERAGE %>% or more. The rule is simple and transparent, and
       the final decision is made by a person (responsible AI, NFR11).</p>
</div></div>
<main class="main-content" id="main">
    <% if (eligible.isEmpty()) { %>
        <div class="card empty-state">
            <div style="display:flex;justify-content:center;margin-bottom:10px;"><iconify-icon icon="tabler:user-search" width="44" height="44" style="color:var(--text-muted);"></iconify-icon></div>
            <p>No participants currently qualify for Level Two promotion.</p>
        </div>
    <% } else { %>
        <div class="card">
            <div class="card-title"><iconify-icon icon="tabler:user-check" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> <%= eligible.size() %> eligible participant(s)</div>
            <div class="table-wrap" style="margin-bottom:16px;">
                <table>
                    <thead><tr>
                        <th scope="col">Name</th><th scope="col">Country</th><th scope="col">Sessions</th>
                        <th scope="col">Average</th><th scope="col">Grade</th><th scope="col">Action</th>
                    </tr></thead>
                    <tbody>
                    <% for (ParticipantProgress row : eligible) {
                           Participant p = row.getParticipant(); %>
                        <tr>
                            <td><strong><%= esc(p.getFullName()) %></strong></td>
                            <td><%= esc(p.getCountry()) %></td>
                            <td><%= row.getSessionsAttended() %></td>
                            <td><%= String.format("%.1f", row.getAverageScore()) %>%</td>
                            <td><span class="badge <%= row.getGradeBadge() %>"><%= row.getGrade() %></span></td>
                            <td>
                                <form action="<%= ctx %>/admin" method="POST" class="inline-form">
                                    <input type="hidden" name="action" value="promoteOne">
                                    <input type="hidden" name="userId" value="<%= p.getUserId() %>">
                                    <button type="submit" class="btn btn-primary btn-sm">
                                        <iconify-icon icon="tabler:trending-up" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Promote
                                    </button>
                                </form>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <form action="<%= ctx %>/admin" method="POST">
                <input type="hidden" name="action" value="promoteAll">
                <button type="submit" class="btn btn-outline"
                        data-confirm="Promote all <%= eligible.size() %> eligible participants to Level Two?">
                    <iconify-icon icon="tabler:rocket" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Promote All Eligible
                </button>
            </form>
        </div>
    <% } %>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
