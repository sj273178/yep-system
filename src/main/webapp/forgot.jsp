<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.util.ValidationUtil" %>
<%--
    Forgot password (FR05). Step 1: enter email. Step 2: enter the 6-digit
    code and a new password. ForgotPasswordServlet does all the checks.
    SMS/email are simulated, so the code is shown on screen in "demo mode".
--%>
<%
    String ctx      = request.getContextPath();
    String error    = (String) request.getAttribute("error");
    String demoCode = (String) request.getAttribute("demoCode");
    String email    = (String) session.getAttribute("resetEmail");
    boolean step2   = email != null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Password — YEP</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>
</head>
<body style="background:linear-gradient(135deg,#064e3b 0%,#166534 100%);min-height:100vh;
             display:flex;align-items:center;justify-content:center;padding:32px 16px;">

<main style="width:100%;max-width:440px;" id="main">
    <div style="text-align:center;margin-bottom:24px;color:white;">
        <div style="width:60px;height:60px;background:rgba(255,255,255,.15);border-radius:16px;
                    display:flex;align-items:center;justify-content:center;margin:0 auto 14px;">
            <iconify-icon icon="tabler:key" width="30" height="30"></iconify-icon>
        </div>
        <h1 style="font-size:1.4rem;margin-bottom:4px;">Reset your password</h1>
        <p style="opacity:.7;font-size:.875rem;">
            <%= step2 ? "Step 2 of 2 — enter the code we sent you" : "Step 1 of 2 — we will send you a one-time code" %>
        </p>
    </div>

    <div class="card" style="border-radius:16px;padding:28px;box-shadow:0 20px 60px rgba(0,0,0,.25);">
        <% if (error != null) { %>
            <div class="alert alert-error" role="alert"><%= ValidationUtil.escapeHtml(error) %></div>
        <% } %>

        <% if (!step2) { %>
            <form method="POST" action="<%= ctx %>/forgot-password">
                <input type="hidden" name="action" value="send">
                <div class="form-group">
                    <label for="email">Email address of your account</label>
                    <input type="email" id="email" name="email" required autocomplete="email" placeholder="you@example.com">
                    <div class="form-hint">We send a 6-digit code by SMS and email. It is valid for 10 minutes.</div>
                </div>
                <button class="btn btn-primary btn-block">
                    <iconify-icon icon="tabler:send" width="16" height="16"></iconify-icon> Send Code
                </button>
            </form>
        <% } else { %>
            <p class="small" style="margin-bottom:12px;">
                If <strong><%= ValidationUtil.escapeHtml(email) %></strong> belongs to a YEP account, a code has been sent to it
                and to the phone number on the account.
            </p>

            <% if (demoCode != null) { %>
                <div class="alert alert-info" style="display:block;">
                    <strong>Demo mode:</strong> SMS and email are simulated in this prototype, so here is the code
                    that was "sent":
                    <div class="demo-code"><%= demoCode %></div>
                </div>
            <% } %>

            <form method="POST" action="<%= ctx %>/forgot-password">
                <input type="hidden" name="action" value="reset">
                <div class="form-group">
                    <label for="code">6-digit code</label>
                    <input type="text" id="code" name="code" required inputmode="numeric" pattern="[0-9]{6}" maxlength="6"
                           autocomplete="one-time-code" style="letter-spacing:.3em;font-weight:700;text-align:center;">
                </div>
                <div class="form-group">
                    <label for="password">New password</label>
                    <input type="password" id="password" name="password" required minlength="8" autocomplete="new-password">
                    <div class="form-hint">At least 8 characters with letters and numbers.</div>
                </div>
                <div class="form-group">
                    <label for="confirm">Confirm new password</label>
                    <input type="password" id="confirm" name="confirm" required minlength="8" autocomplete="new-password">
                </div>
                <button class="btn btn-primary btn-block">
                    <iconify-icon icon="tabler:lock-check" width="16" height="16"></iconify-icon> Save New Password
                </button>
            </form>
            <p class="small" style="text-align:center;margin-top:14px;">
                Didn't get a code? <a href="<%= ctx %>/forgot-password?restart">Start again</a>
            </p>
        <% } %>
    </div>

    <div style="text-align:center;margin-top:20px;">
        <a href="<%= ctx %>/login" style="color:rgba(255,255,255,.7);font-size:.82rem;">
            <iconify-icon icon="tabler:arrow-left" width="14" height="14"></iconify-icon> Back to Sign In
        </a>
    </div>
</main>
</body>
</html>
