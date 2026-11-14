<%@ page contentType="text/html;charset=UTF-8" isErrorPage="true" %>
<%--
    Friendly error page. Servlets put a short "error" message in the request;
    technical details only go to the server log (never shown to users, NFR04).
    web.xml also sends 404 and 500 errors here.
--%>
<%
    String ctx = request.getContextPath();
    Object msg = request.getAttribute("error");
    Integer status = (Integer) request.getAttribute("jakarta.servlet.error.status_code");
    String message;
    if (msg != null)                         message = msg.toString();
    else if (status != null && status == 404) message = "The page you are looking for does not exist.";
    else if (status != null && status == 403) message = "You do not have permission to open this page.";
    else                                     message = "An unexpected error occurred. Please try again.";
    if (status != null) response.setStatus(status);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Something went wrong — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
</head>
<body>
<%@ include file="/WEB-INF/nav.jspf" %>
<main class="main-content" id="main">
    <div class="card empty-state" style="max-width:560px;margin:40px auto;text-align:center;">
        <div style="width:64px;height:64px;border-radius:50%;background:#fee2e2;color:#dc2626;
                    display:flex;align-items:center;justify-content:center;margin:0 auto 14px;">
            <iconify-icon icon="tabler:alert-triangle" width="32" height="32"></iconify-icon>
        </div>
        <h1 style="font-size:1.2rem;margin-bottom:6px;"><%= status != null && status == 404 ? "Page not found" : "Something went wrong" %></h1>
        <p style="color:var(--text-muted);margin-bottom:20px;"><%= esc(message) %></p>
        <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;">
            <a href="javascript:history.back()" class="btn btn-outline">
                <iconify-icon icon="tabler:arrow-left" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Go Back
            </a>
            <a href="<%= ctx %>/login" class="btn btn-primary">
                <iconify-icon icon="tabler:home" width="16" height="16" style="vertical-align:-3px;"></iconify-icon> Home
            </a>
        </div>
    </div>
</main>
</body>
</html>
