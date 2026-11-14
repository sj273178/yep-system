<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,com.yep.util.DateUtil,java.util.*" %>
<%--
    Issue certificates (FR19, use case UC-12). For every participant the page
    shows whether each certificate can be issued, or the reason why not.
      Level One : 3+ sessions and a 50%+ average   (constants in Participant)
      Level Two : team project approved by the mentor
    The rules themselves are checked in CertificateService.
--%>
<%
    List<ParticipantProgress> rows = (List<ParticipantProgress>) request.getAttribute("rows");
    List<Certificate> issued       = (List<Certificate>) request.getAttribute("issued");
    Map<Integer, String> names     = (Map<Integer, String>) request.getAttribute("names");
    if (rows == null) { response.sendRedirect(request.getContextPath() + "/admin?page=certificates"); return; }
    String ctx = request.getContextPath();
%>
<%!
    /** Renders the cell for one certificate type: Issue button, "Issued" badge or the reason. */
    static String certCell(String ctx, int participantId, String certType, String status) {
        if (status == null) {
            return "<form action=\"" + ctx + "/admin\" method=\"POST\" class=\"inline-form\">"
                 + "<input type=\"hidden\" name=\"action\" value=\"issueCert\">"
                 + "<input type=\"hidden\" name=\"participantId\" value=\"" + participantId + "\">"
                 + "<input type=\"hidden\" name=\"certType\" value=\"" + certType + "\">"
                 + "<button type=\"submit\" class=\"btn btn-primary btn-sm\">Issue</button></form>";
        }
        if ("Already issued".equals(status)) return "<span class=\"badge badge-green\">Issued</span>";
        return "<span class=\"small muted\">" + com.yep.util.ValidationUtil.escapeHtml(status) + "</span>";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Certificates — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container">
    <h1>Certificates</h1>
    <p>Level One: <%= Participant.MIN_SESSIONS %>+ sessions and a <%= (int) Participant.CERTIFICATE_AVERAGE %>%+ average.
       Level Two: the team's Impact Project has been approved. Each certificate gets a unique verification code.</p>
</div></div>
<main class="main-content" id="main">
    <div class="card" style="padding:0;overflow:hidden;">
        <div class="table-wrap" style="border:none;border-radius:0;">
            <table>
                <thead><tr>
                    <th scope="col">Participant</th><th scope="col">Level</th><th scope="col">Sessions</th>
                    <th scope="col">Average</th><th scope="col">Level One</th><th scope="col">Level Two</th>
                </tr></thead>
                <tbody>
                <% if (rows.isEmpty()) { %>
                    <tr><td colspan="6" class="muted">No participants registered yet.</td></tr>
                <% } %>
                <% for (ParticipantProgress row : rows) {
                       Participant p = row.getParticipant(); %>
                    <tr>
                        <td><strong><%= esc(p.getFullName()) %></strong><div class="small muted"><%= esc(p.getCountry()) %></div></td>
                        <td><span class="badge badge-grey">L<%= p.getVeLevel() %></span></td>
                        <td><%= row.getSessionsAttended() %></td>
                        <td><%= String.format("%.1f", row.getAverageScore()) %>%</td>
                        <td><%= certCell(ctx, p.getUserId(), Certificate.TYPE_LEVEL1, row.getLevel1Status()) %></td>
                        <td><%= certCell(ctx, p.getUserId(), Certificate.TYPE_LEVEL2, row.getLevel2Status()) %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>

    <div class="card section-gap">
        <div class="card-title"><iconify-icon icon="tabler:certificate" width="18" height="18" style="vertical-align:-3px;"></iconify-icon> Issued Certificates (<%= issued.size() %>)</div>
        <% if (issued.isEmpty()) { %>
            <p class="muted">No certificates issued yet.</p>
        <% } else { %>
        <div class="table-wrap">
            <table>
                <thead><tr><th scope="col">Participant</th><th scope="col">Award</th><th scope="col">Issued</th><th scope="col">Verification code</th><th scope="col"></th></tr></thead>
                <tbody>
                <% for (Certificate c : issued) { %>
                    <tr>
                        <td><%= esc(names.getOrDefault(c.getParticipantId(), "#" + c.getParticipantId())) %></td>
                        <td><%= esc(c.getTypeLabel()) %></td>
                        <td style="white-space:nowrap;"><%= DateUtil.format(c.getIssuedDate()) %></td>
                        <td><code><%= esc(c.getVerificationCode()) %></code></td>
                        <td><a href="<%= ctx %>/certificate?code=<%= esc(c.getVerificationCode()) %>" class="btn btn-outline btn-sm">View</a></td>
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
