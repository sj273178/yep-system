<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.User,com.yep.util.ValidationUtil" %>
<%--
    Participant registration form (FR01–FR03).
    If RegisterServlet finds a problem it forwards back here with an "error"
    attribute; v() refills every field (except passwords) so nothing is lost
    (use case UC-01, alternative flow 4a).
--%>
<%!
    /** Returns the escaped value the user typed for a field, or "". */
    static String v(jakarta.servlet.http.HttpServletRequest r, String name) {
        return ValidationUtil.escapeHtml(r.getParameter(name));
    }
    /** Returns " selected" when the option matches what the user chose. */
    static String sel(jakarta.servlet.http.HttpServletRequest r, String name, String option) {
        return option.equals(r.getParameter(name)) ? " selected" : "";
    }
%>
<%
    String error = (String) request.getAttribute("error");
    String ctx   = request.getContextPath();
    String[] educationLevels = {"Secondary", "Certificate", "Diploma", "Bachelor's Degree", "Postgraduate", "Other"};
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register — YEP System</title>
    <link rel="stylesheet" href="<%= ctx %>/css/style.css">
    <script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>
</head>
<body>
<main class="auth-wrapper" style="align-items:flex-start; padding:40px 16px;" id="main">
    <div class="auth-card" style="max-width:560px;">
        <div class="auth-logo">
            <h1>YEP</h1>
            <p>Create your participant account</p>
        </div>

        <% if (error != null) { %>
            <div class="alert alert-error" role="alert"><%= ValidationUtil.escapeHtml(error) %></div>
        <% } %>

        <p class="form-hint" style="margin-bottom:16px;">
            YEP is open to young people aged 18–35 from East African Community countries.
            Fields marked * are required.
        </p>

        <form action="<%= ctx %>/register" method="POST" id="regForm">

            <div class="form-grid">
                <div class="form-group">
                    <label for="fullName">Full Name *</label>
                    <input type="text" id="fullName" name="fullName" required minlength="3" maxlength="100"
                           value="<%= v(request, "fullName") %>" placeholder="" autocomplete="name">
                </div>
                <div class="form-group">
                    <label for="email">Email Address *</label>
                    <input type="email" id="email" name="email" required maxlength="150"
                           value="<%= v(request, "email") %>" placeholder="" autocomplete="">
                </div>

                <div class="form-group">
                    <label for="phone">Phone Number</label>
                    <input type="tel" id="phone" name="phone" value="<%= v(request, "phone") %>"
                           placeholder="+256 700 000 000" autocomplete="tel">
                    <div class="form-hint">Optional &mdash; used for SMS notifications.</div>
                </div>
                <div class="form-group">
                    <label for="country">Country *</label>
                    <select id="country" name="country" required>
                        <option value=""> Select EAC Country </option>
                        <% for (String c : User.EAC_COUNTRIES) { %>
                            <option<%= sel(request, "country", c) %>><%= c %></option>
                        <% } %>
                    </select>
                </div>

                <div class="form-group">
                    <label for="dateOfBirth">Date of Birth * <span class="form-hint">(age 18–35)</span></label>
                    <input type="date" id="dateOfBirth" name="dateOfBirth" required value="<%= v(request, "dateOfBirth") %>">
                </div>
                <div class="form-group">
                    <label for="gender">Gender *</label>
                    <select id="gender" name="gender" required>
                        <option value=""> Select </option>
                        <% for (String g : ValidationUtil.GENDERS) { %>
                            <option<%= sel(request, "gender", g) %>><%= g %></option>
                        <% } %>
                    </select>
                </div>

                <div class="form-group">
                    <label for="district">District / Region</label>
                    <input type="text" id="district" name="district" maxlength="100"
                           value="<%= v(request, "district") %>" placeholder="">
                </div>
                <div class="form-group">
                    <label for="educationLevel">Education Level</label>
                    <select id="educationLevel" name="educationLevel">
                        <option value=""> Select </option>
                        <% for (String e : educationLevels) { %>
                            <option<%= sel(request, "educationLevel", e) %>><%= ValidationUtil.escapeHtml(e) %></option>
                        <% } %>
                    </select>
                </div>

                <div class="form-group">
                    <label for="password">Password *</label>
                    <input type="password" id="password" name="password" required minlength="8"
                           placeholder="" autocomplete="new-password"
                           aria-describedby="strengthLabel">
                    <div style="background:#e0e0e0;border-radius:3px;height:5px;margin-top:6px;">
                        <div id="strengthBar" style="height:5px;border-radius:3px;width:0;transition:width .3s;"></div>
                    </div>
                    <span id="strengthLabel" class="form-hint" aria-live="polite"></span>
                </div>
                <div class="form-group">
                    <label for="confirmPassword">Confirm Password *</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" required
                           placeholder="" autocomplete="new-password" aria-describedby="matchMsg">
                    <span id="matchMsg" class="form-hint" aria-live="polite"></span>
                </div>
            </div>


            <div class="form-group">
                <div class="checkbox-row">
                    <input type="checkbox" id="consent" name="consent" required>
                    <label for="consent">
                        I consent to YEP collecting and processing my personal data for the Youth Empowerment
                        Programme, in line with Uganda's Data Protection and Privacy Act 2019. *
                    </label>
                </div>
            </div>

            <button type="submit" class="btn btn-primary btn-block">
                <iconify-icon icon="tabler:user-plus" width="16" height="16" style="vertical-align:-3px;"></iconify-icon>
                Create Account
            </button>
        </form>

        <div class="auth-footer">
            Already have an account? <a href="<%= ctx %>/login">Sign in</a>
        </div>
    </div>
</main>

<script src="<%= ctx %>/js/main.js"></script>
<script>
    /* Live password match check */
    document.getElementById('confirmPassword').addEventListener('input', function () {
        var msg = document.getElementById('matchMsg');
        var same = this.value === document.getElementById('password').value;
        msg.textContent = same ? 'Passwords match' : 'Passwords do not match';
        msg.style.color = same ? 'green' : '#b91c1c';
    });

    /* Quick age check in the browser (the server checks again) */
    document.getElementById('regForm').addEventListener('submit', function (e) {
        var value = document.getElementById('dateOfBirth').value;
        if (!value) return;
        var dob = new Date(value), today = new Date();
        var age = today.getFullYear() - dob.getFullYear();
        var m = today.getMonth() - dob.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) age--;
        if (age < 18 || age > 35) {
            alert('YEP is for youth aged 18 to 35 only.');
            e.preventDefault();
        }
    });
</script>
</body>
</html>
