<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.Certificate,com.yep.util.ValidationUtil,com.yep.util.DateUtil" %>
<%-- Public certificate verification page (FR20) — no login required. --%>
<%
    Certificate cert            = (Certificate) request.getAttribute("certificate");
    String      participantName = (String)      request.getAttribute("participantName");
    Boolean     valid           = (Boolean)     request.getAttribute("valid");
    String      ctx             = request.getContextPath();
    String      error           = (String)      request.getAttribute("error");
    String      typedCode       = request.getParameter("code") != null ? request.getParameter("code").trim() : "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verify Certificate — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
<script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>
</head>
<body style="background:linear-gradient(135deg,#064e3b 0%,#166534 100%);min-height:100vh;
             display:flex;align-items:center;justify-content:center;padding:32px 16px;">

<main style="width:100%;max-width:520px;" id="main">

    <div style="text-align:center;margin-bottom:28px;">
        <div style="width:60px;height:60px;background:rgba(255,255,255,.15);border-radius:16px;
                    display:flex;align-items:center;justify-content:center;
                    font-size:1.6rem;font-weight:800;color:white;margin:0 auto 14px;">Y</div>
        <h1 style="color:white;font-size:1.4rem;margin-bottom:4px;">Certificate Verification</h1>
        <p style="color:rgba(255,255,255,.65);font-size:.875rem;">
            Youth Empowerment Project — No login required
        </p>
    </div>

    <div style="background:white;border-radius:16px;padding:32px;box-shadow:0 20px 60px rgba(0,0,0,.25);">

        <% if (error != null) { %>
            <div class="alert alert-error" role="alert"><%= ValidationUtil.escapeHtml(error) %></div>
        <% } %>

        <%-- Search form --%>
        <form action="<%= ctx %>/verify" method="GET">
            <div class="form-group" style="margin-bottom:12px;">
                <label for="code" style="font-size:.85rem;">Enter Certificate Code</label>
                <input type="text" id="code" name="code" required maxlength="50"
                       placeholder="e.g. YEP-K7MP-Q3XR"
                       style="text-transform:uppercase;letter-spacing:.1em;font-weight:600;"
                       value="<%= ValidationUtil.escapeHtml(typedCode) %>">
            </div>
            <button type="submit" class="btn btn-primary btn-block">Verify Certificate</button>
        </form>

        <%-- Result --%>
        <% if (valid != null) { %>
            <hr style="border:none;border-top:1px solid var(--border);margin:24px 0;">

            <% if (valid) { %>
                <%-- Valid certificate --%>
                <div style="text-align:center;margin-bottom:16px;">
                    <div style="width:56px;height:56px;background:#dcfce7;border-radius:50%;
                                display:flex;align-items:center;justify-content:center;
                                color:#16a34a;margin:0 auto 10px;"><iconify-icon icon="tabler:circle-check" width="30" height="30"></iconify-icon></div>
                    <div style="font-weight:700;font-size:1.1rem;color:#166534;">Certificate is Genuine</div>
                    <div style="font-size:.85rem;color:var(--text-muted);margin-top:4px;">
                        Issued by the YEP Secretariat
                    </div>
                </div>

                <div style="background:var(--bg);border-radius:var(--radius);padding:20px;margin-bottom:16px;">
                    <div style="display:flex;flex-direction:column;gap:12px;">
                        <div>
                            <div style="font-size:.72rem;text-transform:uppercase;letter-spacing:.07em;color:var(--text-muted);font-weight:600;">Participant</div>
                            <div style="font-weight:700;font-size:1rem;margin-top:2px;"><%= ValidationUtil.escapeHtml(participantName) %></div>
                        </div>
                        <div>
                            <div style="font-size:.72rem;text-transform:uppercase;letter-spacing:.07em;color:var(--text-muted);font-weight:600;">Award</div>
                            <div style="font-weight:600;margin-top:2px;"><%= ValidationUtil.escapeHtml(cert.getTypeLabel()) %></div>
                        </div>
                        <div>
                            <div style="font-size:.72rem;text-transform:uppercase;letter-spacing:.07em;color:var(--text-muted);font-weight:600;">Date Issued</div>
                            <div style="font-weight:600;margin-top:2px;"><%= DateUtil.formatLong(cert.getIssuedDate()) %></div>
                        </div>
                        <div>
                            <div style="font-size:.72rem;text-transform:uppercase;letter-spacing:.07em;color:var(--text-muted);font-weight:600;">Verification Code</div>
                            <code style="background:white;border:1px solid var(--border);padding:4px 10px;
                                         border-radius:6px;font-size:.85rem;letter-spacing:.08em;
                                         margin-top:4px;display:inline-block;">
                                <%= ValidationUtil.escapeHtml(cert.getVerificationCode()) %>
                            </code>
                        </div>
                    </div>
                </div>

                <%-- View full certificate button --%>
                <a href="<%= ctx %>/certificate?code=<%= java.net.URLEncoder.encode(cert.getVerificationCode(), "UTF-8") %>"
                   style="display:flex;align-items:center;justify-content:center;gap:8px;
                          padding:13px;border-radius:var(--radius);background:#14532d;
                          color:white;font-weight:700;font-size:.9rem;text-decoration:none;">
                    <iconify-icon icon="tabler:file-certificate" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> View &amp; Print Full Certificate
                </a>

            <% } else { %>
                <%-- Invalid --%>
                <div style="text-align:center;">
                    <div style="width:56px;height:56px;background:#fee2e2;border-radius:50%;
                                display:flex;align-items:center;justify-content:center;
                                color:#dc2626;margin:0 auto 10px;"><iconify-icon icon="tabler:circle-x" width="30" height="30"></iconify-icon></div>
                    <div style="font-weight:700;font-size:1.1rem;color:#991b1b;">Certificate Not Found</div>
                    <div style="font-size:.85rem;color:var(--text-muted);margin-top:8px;">
                        The code "<strong><%= ValidationUtil.escapeHtml(typedCode) %></strong>"
                        does not match any issued certificate. Please check and try again.
                    </div>
                </div>
            <% } %>
        <% } %>
    </div>

    <div style="text-align:center;margin-top:20px;">
        <a href="<%= ctx %>/login" style="color:rgba(255,255,255,.6);font-size:.82rem;">
            <iconify-icon icon="tabler:arrow-left" width="14" height="14" style="vertical-align:-2px;"></iconify-icon> Back to Login
        </a>
    </div>
</main>
</body>
</html>
