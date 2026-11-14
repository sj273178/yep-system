<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.*,java.util.*" %>
<%--
    Programme reports (FR21) for administrators and donors: participants by
    country, gender and level; attendance by mode; certificates; projects.
    Only aggregated numbers are shown — no personal data (report section 8.2).
--%>
<%!
    /** Draws one labelled horizontal bar. */
    static String bar(String label, int value, int total, String colour) {
        long pct = total > 0 ? Math.round(value * 100.0 / total) : 0;
        return "<div class=\"bar-row\"><div class=\"bar-head\"><span>" + com.yep.util.ValidationUtil.escapeHtml(label)
             + "</span><span>" + value + " (" + pct + "%)</span></div>"
             + "<div class=\"progress-track\"><div class=\"progress-fill\" style=\"width:" + pct + "%;"
             + (colour != null ? "background:" + colour + ";" : "") + "\"></div></div></div>";
    }

    static int sum(Map<String, Integer> map) {
        int total = 0;
        for (int v : map.values()) total += v;
        return total;
    }

    static String nice(String raw) {
        switch (raw) {
            case "video":    return "Video";
            case "audio":    return "Audio only";
            case "download": return "Downloaded notes";
            case "draft":    return "Draft";
            case "submitted":return "Submitted";
            case "approved": return "Approved";
            case "revision_requested": return "Revision requested";
            default:         return Certificate.typeLabel(raw);
        }
    }
%>
<%
    if (request.getAttribute("byCountry") == null) { response.sendRedirect(request.getContextPath() + "/admin?page=reports"); return; }
    int totalParticipants = (Integer) request.getAttribute("totalParticipants");
    Map<String, Integer> byCountry  = (Map<String, Integer>) request.getAttribute("byCountry");
    Map<String, Integer> byGender   = (Map<String, Integer>) request.getAttribute("byGender");
    Map<String, Integer> byLevel    = (Map<String, Integer>) request.getAttribute("byLevel");
    Map<String, Integer> byMode     = (Map<String, Integer>) request.getAttribute("byMode");
    Map<String, Integer> certsByType = (Map<String, Integer>) request.getAttribute("certsByType");
    Map<String, Integer> projects    = (Map<String, Integer>) request.getAttribute("projectsByStatus");
    double avgScore = (Double) request.getAttribute("averageScore");
    String ctx = request.getContextPath();
    Map<String, String> genderColours = Map.of("Male", "#2563eb", "Female", "#db2777", "Other", "#7c3aed");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<div class="page-header"><div class="container" style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;">
    <div>
        <h1>Programme Reports</h1>
        <p>Aggregated figures for partners and donors — no personal data is shown.</p>
    </div>
    <button type="button" class="btn btn-outline" style="background:white;" onclick="window.print()">
        <iconify-icon icon="tabler:printer" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Print
    </button>
</div></div>
<main class="main-content" id="main">
    <div class="stats-grid">
        <div class="stat-card"><span class="stat-icon"><iconify-icon icon="tabler:school" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= totalParticipants %></div><div class="label">Participants</div></div>
        <div class="stat-card"><span class="stat-icon"><iconify-icon icon="tabler:calendar-event" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= request.getAttribute("sessionsHeld") %></div><div class="label">Sessions Held</div></div>
        <div class="stat-card"><span class="stat-icon"><iconify-icon icon="tabler:user-check" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= request.getAttribute("attendance") %></div><div class="label">Attendances</div></div>
        <div class="stat-card"><span class="stat-icon"><iconify-icon icon="tabler:chart-line" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= String.format("%.0f", avgScore) %>%</div><div class="label">Average Score</div></div>
        <div class="stat-card"><span class="stat-icon"><iconify-icon icon="tabler:certificate" width="22" height="22"></iconify-icon></span>
            <div class="number"><%= request.getAttribute("certificates") %></div><div class="label">Certificates</div></div>
    </div>

    <div class="two-col">
        <div class="card">
            <div class="card-title">Participants by Country</div>
            <% if (byCountry.isEmpty()) { %><p class="muted">No data yet.</p><% } %>
            <% for (Map.Entry<String, Integer> e : byCountry.entrySet()) { %>
                <%= bar(e.getKey(), e.getValue(), totalParticipants, null) %>
            <% } %>
        </div>
        <div class="card">
            <div class="card-title">Participants by Gender</div>
            <% if (byGender.isEmpty()) { %><p class="muted">No data yet.</p><% } %>
            <% for (Map.Entry<String, Integer> e : byGender.entrySet()) { %>
                <%= bar(e.getKey(), e.getValue(), totalParticipants, genderColours.get(e.getKey())) %>
            <% } %>
        </div>
        <div class="card">
            <div class="card-title">Participants by Level</div>
            <% if (byLevel.isEmpty()) { %><p class="muted">No data yet.</p><% } %>
            <% for (Map.Entry<String, Integer> e : byLevel.entrySet()) { %>
                <%= bar(e.getKey(), e.getValue(), totalParticipants, null) %>
            <% } %>
        </div>
        <div class="card">
            <div class="card-title">Attendance by Mode <span class="small muted">(low-bandwidth use)</span></div>
            <% if (byMode.isEmpty()) { %><p class="muted">No attendance yet.</p><% } %>
            <% int modeTotal = sum(byMode);
               for (Map.Entry<String, Integer> e : byMode.entrySet()) { %>
                <%= bar(nice(e.getKey()), e.getValue(), modeTotal, "#0891b2") %>
            <% } %>
        </div>
        <div class="card">
            <div class="card-title">Certificates Issued</div>
            <% if (certsByType.isEmpty()) { %><p class="muted">No certificates issued yet.</p><% } %>
            <% for (Map.Entry<String, Integer> e : certsByType.entrySet()) { %>
                <%= bar(nice(e.getKey()), e.getValue(), totalParticipants, "#d97706") %>
            <% } %>
            <p class="small muted">Percentages are of all participants.</p>
        </div>
        <div class="card">
            <div class="card-title">Impact Projects by Status</div>
            <% if (projects.isEmpty()) { %><p class="muted">No projects yet.</p><% } %>
            <% int projectTotal = sum(projects);
               for (Map.Entry<String, Integer> e : projects.entrySet()) { %>
                <%= bar(nice(e.getKey()), e.getValue(), projectTotal, "#7c3aed") %>
            <% } %>
        </div>
    </div>
</main>
<footer>YEP System &mdash; Youth Empowerment Project &copy; 2026</footer>
<script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
