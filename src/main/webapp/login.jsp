<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.util.FlashMessage,com.yep.util.ValidationUtil" %>
<%--
    Login page (FR04). LoginServlet forwards here with an "error" attribute
    when sign-in fails; other pages leave a one-time "flash" message
    (e.g. "Account created", "Signed out") in the session.
--%>
<%
    String error = (String) request.getAttribute("error");
    FlashMessage flash = (FlashMessage) session.getAttribute(FlashMessage.SESSION_KEY);
    if (flash != null) session.removeAttribute(FlashMessage.SESSION_KEY);
    String typedEmail = request.getParameter("email") != null ? request.getParameter("email") : "";
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In — YEP System</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Playfair+Display:wght@700;900&display=swap" rel="stylesheet">
    <script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Inter', system-ui, sans-serif;
            min-height: 100vh;
            display: flex;
            -webkit-font-smoothing: antialiased;
        }

        /* ======================================================
           LEFT PANEL — 50%
           ====================================================== */
        .left-panel {
            display: none;
            width: 50%;
            background: linear-gradient(160deg, #052e16 0%, #14532d 55%, #15803d 100%);
            padding: 48px 56px;
            flex-direction: column;
            justify-content: space-between;
            position: relative;
            overflow: hidden;
        }
        @media (min-width: 820px) { .left-panel { display: flex; } }

        /* Subtle radial glows */
        .left-panel::before {
            content: '';
            position: absolute; top: -100px; right: -100px;
            width: 350px; height: 350px;
            background: radial-gradient(circle, rgba(74,222,128,.12) 0%, transparent 70%);
            border-radius: 50%; pointer-events: none;
        }
        .left-panel::after {
            content: '';
            position: absolute; bottom: -80px; left: -60px;
            width: 280px; height: 280px;
            background: radial-gradient(circle, rgba(250,204,21,.07) 0%, transparent 70%);
            border-radius: 50%; pointer-events: none;
        }

        /* Brand top-left */
        .lp-brand {
            display: flex; align-items: center; gap: 10px;
            position: relative; z-index: 2;
        }
        .lp-brand-icon {
            width: 38px; height: 38px;
            background: rgba(255,255,255,.12);
            border: 1px solid rgba(255,255,255,.2);
            border-radius: 9px;
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; color: white; font-size: .9rem;
        }
        .lp-brand-text { color: rgba(255,255,255,.9); font-weight: 700; font-size: .95rem; }

        /* Centre illustration block */
        .lp-center { position: relative; z-index: 2; flex: 1; display: flex;
                      flex-direction: column; justify-content: center; align-items: center;
                      padding: 32px 0; }

        .lp-title {
            font-family: 'Playfair Display', serif;
            font-size: 3.2rem; font-weight: 900;
            color: white; letter-spacing: -.03em;
            text-align: center; line-height: 1.1; margin-top: 32px;
        }
        .lp-title span { color: #4ade80; }

        .lp-sub {
            text-align: center; color: rgba(255,255,255,.6);
            font-size: .9rem; margin-top: 12px; line-height: 1.6;
            max-width: 320px;
        }

        /* Bottom stats */
        .lp-stats {
            display: grid; grid-template-columns: 1fr 1fr;
            gap: 10px; position: relative; z-index: 2;
        }
        .lp-stat {
            background: rgba(255,255,255,.07);
            border: 1px solid rgba(255,255,255,.1);
            border-radius: 10px; padding: 14px 16px;
        }
        .lp-stat .n { font-size: 1.4rem; font-weight: 800; color: white; }
        .lp-stat .l { font-size: .72rem; color: rgba(255,255,255,.5);
                      text-transform: uppercase; letter-spacing: .07em; margin-top: 2px; }

        /* ======================================================
           RIGHT PANEL — 50%
           ====================================================== */
        .right-panel {
            width: 100%;
            display: flex; align-items: center; justify-content: center;
            padding: 32px 20px;
            background: #f9fafb;
        }
        @media (min-width: 820px) { .right-panel { width: 50%; } }

        .form-card { width: 100%; max-width: 380px; }

        /* Mobile logo */
        .mobile-logo { display: flex; align-items: center; gap: 10px; margin-bottom: 28px; }
        @media (min-width: 820px) { .mobile-logo { display: none; } }
        .m-logo-mark {
            width: 38px; height: 38px; border-radius: 9px;
            background: linear-gradient(135deg,#14532d,#16a34a);
            display: flex; align-items: center; justify-content: center;
            color: white; font-weight: 800; font-size: .9rem;
        }
        .m-logo-text  { font-weight: 700; font-size: .95rem; color: #111; }
        .m-logo-sub   { font-size: .72rem; color: #9ca3af; }

        /* Heading */
        .form-heading { margin-bottom: 24px; }
        .form-heading h1 { font-size: 1.45rem; font-weight: 800; color: #111; letter-spacing: -.03em; }
        .form-heading p  { color: #6b7280; font-size: .85rem; margin-top: 4px; }

        /* Role grid */
        .role-label {
            font-size: .72rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: .09em;
            color: #9ca3af; margin-bottom: 8px;
        }
        .role-grid {
            display: grid; grid-template-columns: 1fr 1fr;
            gap: 8px; margin-bottom: 20px;
        }
        .role-btn {
            display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            gap: 7px; padding: 14px 10px;
            border: 1.5px solid #e5e7eb;
            border-radius: 10px; background: white;
            cursor: pointer; transition: all .18s;
            position: relative; font-family: inherit;
        }
        .role-btn:hover { border-color: #86efac; background: #f0fdf4; }
        .role-btn.active {
            border-color: #16a34a;
            background: linear-gradient(145deg, #f0fdf4, #dcfce7);
            box-shadow: 0 0 0 3px rgba(22,163,74,.12);
        }
        .role-icon-wrap {
            width: 36px; height: 36px; border-radius: 9px;
            background: #f3f4f6; display: flex;
            align-items: center; justify-content: center;
            transition: background .18s;
        }
        .role-btn.active .role-icon-wrap { background: #16a34a; }
        .role-btn .role-icon-wrap svg  { stroke: #6b7280; transition: stroke .18s; }
        .role-btn.active .role-icon-wrap svg { stroke: white; }
        .role-btn .role-name {
            font-size: .78rem; font-weight: 600; color: #374151; line-height: 1;
        }
        .role-btn.active .role-name { color: #14532d; }
        .check-dot {
            position: absolute; top: 6px; right: 6px;
            width: 16px; height: 16px; border-radius: 50%;
            background: #16a34a; display: none;
            align-items: center; justify-content: center;
        }
        .role-btn.active .check-dot { display: flex; }

        /* Hint */
        .hint-bar {
            display: flex; align-items: center; gap: 8px;
            padding: 9px 13px; border-radius: 8px;
            background: #f0fdf4; border: 1px solid #bbf7d0;
            margin-bottom: 18px; font-size: .8rem; color: #166534; font-weight: 500;
        }

        /* Fields */
        .field { margin-bottom: 14px; }
        .field label { display:block; font-size:.8rem; font-weight:600; color:#374151; margin-bottom:5px; }
        .input-wrap { position: relative; }
        .input-wrap svg { position:absolute; left:12px; top:50%; transform:translateY(-50%);
                          stroke:#9ca3af; pointer-events:none; }
        .input-wrap input {
            width:100%; padding:10px 12px 10px 38px;
            border:1.5px solid #e5e7eb; border-radius:8px;
            font-size:.9rem; color:#111; background:white;
            font-family:inherit; transition:border-color .18s, box-shadow .18s;
        }
        .input-wrap input:focus {
            outline:none; border-color:#16a34a;
            box-shadow:0 0 0 3px rgba(22,163,74,.12);
        }
        .input-wrap input::placeholder { color:#d1d5db; }

        /* Submit */
        .submit-btn {
            width:100%; padding:12px; margin-top:4px;
            background:linear-gradient(135deg,#15803d,#16a34a);
            color:white; border:none; border-radius:8px;
            font-size:.95rem; font-weight:700; cursor:pointer;
            font-family:inherit; letter-spacing:-.01em;
            box-shadow:0 4px 14px rgba(22,163,74,.35);
            transition:all .18s;
            display:flex; align-items:center; justify-content:center; gap:8px;
        }
        .submit-btn:hover { box-shadow:0 6px 18px rgba(22,163,74,.45); transform:translateY(-1px); }
        .submit-btn:active { transform:translateY(0); }

        /* Divider */
        .divider { display:flex; align-items:center; gap:10px; margin:18px 0;
                   color:#9ca3af; font-size:.78rem; }
        .divider::before, .divider::after { content:''; flex:1; height:1px; background:#e5e7eb; }

        /* Footer */
        .form-footer { text-align:center; font-size:.82rem; color:#6b7280; }
        .form-footer a { color:#16a34a; font-weight:600; }
        .verify-link { display:flex; align-items:center; justify-content:center;
                       gap:5px; margin-top:10px; font-size:.78rem; color:#9ca3af;
                       text-decoration:none; }
        .verify-link:hover { color:#6b7280; }

        /* Alert */
        .alert { padding:11px 14px; border-radius:8px; margin-bottom:14px;
                 font-size:.82rem; display:flex; align-items:flex-start; gap:8px; }
        .alert-success { background:#dcfce7; border:1px solid #86efac; color:#166534; }
        .alert-info    { background:#dbeafe; border:1px solid #93c5fd; color:#1e40af; }
        .alert-error   { background:#fee2e2; border:1px solid #fca5a5; color:#991b1b; }
        .alert-warning { background:#fef3c7; border:1px solid #fcd34d; color:#92400e; }
    </style>
</head>
<body>

<!-- ============ LEFT PANEL ============ -->
<div class="left-panel">

    <div class="lp-brand">
        <div class="lp-brand-icon">Y</div>
        <span class="lp-brand-text">YEP System</span>
    </div>

    <div class="lp-center">

        <!-- Collaboration SVG illustration -->
        <svg viewBox="0 0 420 320" fill="none" xmlns="http://www.w3.org/2000/svg"
             style="width:100%;max-width:380px;">

            <!-- Connection lines (behind everything) -->
            <line x1="130" y1="120" x2="210" y2="85"  stroke="rgba(74,222,128,.35)" stroke-width="1.5" stroke-dasharray="5 4"/>
            <line x1="290" y1="120" x2="210" y2="85"  stroke="rgba(74,222,128,.35)" stroke-width="1.5" stroke-dasharray="5 4"/>
            <line x1="80"  y1="220" x2="130" y2="120" stroke="rgba(74,222,128,.25)" stroke-width="1.5" stroke-dasharray="5 4"/>
            <line x1="340" y1="220" x2="290" y2="120" stroke="rgba(74,222,128,.25)" stroke-width="1.5" stroke-dasharray="5 4"/>
            <line x1="175" y1="230" x2="130" y2="120" stroke="rgba(74,222,128,.25)" stroke-width="1.5" stroke-dasharray="5 4"/>
            <line x1="245" y1="230" x2="290" y2="120" stroke="rgba(74,222,128,.25)" stroke-width="1.5" stroke-dasharray="5 4"/>
            <line x1="175" y1="230" x2="210" y2="85"  stroke="rgba(74,222,128,.15)" stroke-width="1"   stroke-dasharray="4 5"/>
            <line x1="245" y1="230" x2="210" y2="85"  stroke="rgba(74,222,128,.15)" stroke-width="1"   stroke-dasharray="4 5"/>

            <!-- ---- Central hub node ---- -->
            <circle cx="210" cy="85" r="34" fill="rgba(255,255,255,.08)" stroke="rgba(255,255,255,.2)" stroke-width="1.5"/>
            <circle cx="210" cy="85" r="24" fill="#16a34a"/>
            <!-- Hub icon — people/network -->
            <circle cx="210" cy="80" r="6" fill="white"/>
            <path d="M198 95 Q210 88 222 95" stroke="white" stroke-width="2" fill="none" stroke-linecap="round"/>

            <!-- ---- Left node (Kenya) ---- -->
            <circle cx="130" cy="120" r="26" fill="rgba(255,255,255,.07)" stroke="rgba(255,255,255,.18)" stroke-width="1.5"/>
            <circle cx="130" cy="120" r="18" fill="rgba(255,255,255,.12)"/>
            <!-- Person icon -->
            <circle cx="130" cy="115" r="5" fill="rgba(255,255,255,.85)"/>
            <path d="M120 128 Q130 122 140 128" stroke="rgba(255,255,255,.85)" stroke-width="1.8" fill="none" stroke-linecap="round"/>
            <text x="130" y="152" text-anchor="middle" fill="rgba(255,255,255,.55)" font-size="9" font-family="Inter,sans-serif" font-weight="600">Kenya</text>

            <!-- ---- Right node (Uganda) ---- -->
            <circle cx="290" cy="120" r="26" fill="rgba(255,255,255,.07)" stroke="rgba(255,255,255,.18)" stroke-width="1.5"/>
            <circle cx="290" cy="120" r="18" fill="rgba(255,255,255,.12)"/>
            <circle cx="290" cy="115" r="5" fill="rgba(255,255,255,.85)"/>
            <path d="M280 128 Q290 122 300 128" stroke="rgba(255,255,255,.85)" stroke-width="1.8" fill="none" stroke-linecap="round"/>
            <text x="290" y="152" text-anchor="middle" fill="rgba(255,255,255,.55)" font-size="9" font-family="Inter,sans-serif" font-weight="600">Uganda</text>

            <!-- ---- Bottom-left node (Rwanda) ---- -->
            <circle cx="80" cy="220" r="22" fill="rgba(255,255,255,.06)" stroke="rgba(255,255,255,.15)" stroke-width="1.5"/>
            <circle cx="80" cy="220" r="15" fill="rgba(255,255,255,.1)"/>
            <circle cx="80" cy="216" r="4" fill="rgba(255,255,255,.8)"/>
            <path d="M72 227 Q80 222 88 227" stroke="rgba(255,255,255,.8)" stroke-width="1.5" fill="none" stroke-linecap="round"/>
            <text x="80" y="250" text-anchor="middle" fill="rgba(255,255,255,.45)" font-size="8.5" font-family="Inter,sans-serif" font-weight="600">Rwanda</text>

            <!-- ---- Bottom-right node (Tanzania) ---- -->
            <circle cx="340" cy="220" r="22" fill="rgba(255,255,255,.06)" stroke="rgba(255,255,255,.15)" stroke-width="1.5"/>
            <circle cx="340" cy="220" r="15" fill="rgba(255,255,255,.1)"/>
            <circle cx="340" cy="216" r="4" fill="rgba(255,255,255,.8)"/>
            <path d="M332 227 Q340 222 348 227" stroke="rgba(255,255,255,.8)" stroke-width="1.5" fill="none" stroke-linecap="round"/>
            <text x="340" y="250" text-anchor="middle" fill="rgba(255,255,255,.45)" font-size="8.5" font-family="Inter,sans-serif" font-weight="600">Tanzania</text>

            <!-- ---- Bottom-centre nodes (Burundi / DR Congo) ---- -->
            <circle cx="175" cy="230" r="18" fill="rgba(255,255,255,.06)" stroke="rgba(255,255,255,.12)" stroke-width="1"/>
            <circle cx="175" cy="226" r="4" fill="rgba(255,255,255,.7)"/>
            <path d="M168 235 Q175 230 182 235" stroke="rgba(255,255,255,.7)" stroke-width="1.5" fill="none" stroke-linecap="round"/>
            <text x="175" y="258" text-anchor="middle" fill="rgba(255,255,255,.4)" font-size="7.5" font-family="Inter,sans-serif" font-weight="600">Burundi</text>

            <circle cx="245" cy="230" r="18" fill="rgba(255,255,255,.06)" stroke="rgba(255,255,255,.12)" stroke-width="1"/>
            <circle cx="245" cy="226" r="4" fill="rgba(255,255,255,.7)"/>
            <path d="M238 235 Q245 230 252 235" stroke="rgba(255,255,255,.7)" stroke-width="1.5" fill="none" stroke-linecap="round"/>
            <text x="245" y="258" text-anchor="middle" fill="rgba(255,255,255,.4)" font-size="7.5" font-family="Inter,sans-serif" font-weight="600">DR Congo</text>

            <!-- Floating accent dots -->
            <circle cx="55"  cy="150" r="3" fill="rgba(74,222,128,.4)"/>
            <circle cx="370" cy="155" r="3" fill="rgba(74,222,128,.4)"/>
            <circle cx="210" cy="275" r="3" fill="rgba(74,222,128,.3)"/>
            <circle cx="155" cy="60"  r="2" fill="rgba(250,204,21,.35)"/>
            <circle cx="265" cy="55"  r="2" fill="rgba(250,204,21,.35)"/>
            <circle cx="40"  cy="95"  r="2" fill="rgba(255,255,255,.2)"/>
            <circle cx="380" cy="90"  r="2" fill="rgba(255,255,255,.2)"/>

        </svg>

        <h1 class="lp-title">Youth<br><span>Empowerment</span><br>Project</h1>
        <p class="lp-sub">Connecting young people across East Africa for digital learning, mentorship and impact.</p>
    </div>

    <div class="lp-stats">
        <div class="lp-stat"><div class="n">8</div><div class="l">EAC Countries</div></div>
        <div class="lp-stat"><div class="n">2</div><div class="l">Programme Levels</div></div>
        <div class="lp-stat"><div class="n">100%</div><div class="l">Free Access</div></div>
        <div class="lp-stat"><div class="n"><iconify-icon icon="tabler:rosette-discount-check" width="26" height="26"></iconify-icon></div><div class="l">Verified Certificates</div></div>
    </div>

</div><!-- /left-panel -->


<!-- ============ RIGHT PANEL ============ -->
<div class="right-panel">
    <div class="form-card">

        <div class="mobile-logo">
            <div class="m-logo-mark">Y</div>
            <div>
                <div class="m-logo-text">YEP System</div>
                <div class="m-logo-sub">Youth Empowerment Project</div>
            </div>
        </div>

        <div class="form-heading">
            <h1>Sign in</h1>
            <p>Select your role and enter your credentials</p>
        </div>

        <% if (error != null) { %>
            <div class="alert alert-error" role="alert"><%= ValidationUtil.escapeHtml(error) %></div>
        <% } else if (flash != null) { %>
            <div class="alert alert-<%= ValidationUtil.escapeHtml(flash.getType()) %>" role="status">
                <%= ValidationUtil.escapeHtml(flash.getText()) %>
            </div>
        <% } %>

        <div class="role-label">I am a</div>
        <div class="role-grid">

            <button class="role-btn active" onclick="selectRole('participant',this)" type="button">
                <div class="role-icon-wrap">
                    <iconify-icon icon="tabler:school" width="18" height="18"></iconify-icon>
                </div>
                <span class="role-name">Participant</span>
                <span class="check-dot">
                    <iconify-icon icon="tabler:check" width="10" height="10" style="color:white;"></iconify-icon>
                </span>
            </button>

            <button class="role-btn" onclick="selectRole('facilitator',this)" type="button">
                <div class="role-icon-wrap">
                    <iconify-icon icon="tabler:book" width="18" height="18"></iconify-icon>
                </div>
                <span class="role-name">Facilitator</span>
                <span class="check-dot">
                    <iconify-icon icon="tabler:check" width="10" height="10" style="color:white;"></iconify-icon>
                </span>
            </button>

            <button class="role-btn" onclick="selectRole('mentor',this)" type="button">
                <div class="role-icon-wrap">
                    <iconify-icon icon="tabler:users" width="18" height="18"></iconify-icon>
                </div>
                <span class="role-name">Mentor</span>
                <span class="check-dot">
                    <iconify-icon icon="tabler:check" width="10" height="10" style="color:white;"></iconify-icon>
                </span>
            </button>

            <button class="role-btn" onclick="selectRole('admin',this)" type="button">
                <div class="role-icon-wrap">
                    <iconify-icon icon="tabler:shield-check" width="18" height="18"></iconify-icon>
                </div>
                <span class="role-name">Admin</span>
                <span class="check-dot">
                    <iconify-icon icon="tabler:check" width="10" height="10" style="color:white;"></iconify-icon>
                </span>
            </button>

        </div>

        <div class="hint-bar" id="hintBar">
            <iconify-icon icon="tabler:info-circle" width="14" height="14" style="color:#16a34a;"></iconify-icon>
            <span id="hintText">Enter your participant email and password</span>
        </div>

        <form action="<%= ctx %>/login" method="POST">
            <div class="field">
                <label for="email">Email Address</label>
                <div class="input-wrap">
                    <iconify-icon icon="tabler:mail" width="16" height="16"></iconify-icon>
                    <input type="email" id="email" name="email" required
                           value="<%= ValidationUtil.escapeHtml(typedEmail) %>"
                           placeholder="you@example.com" autocomplete="email">
                </div>
            </div>
            <div class="field">
                <label for="password" style="display:flex;justify-content:space-between;">
                    Password <a href="<%= ctx %>/forgot-password?restart" style="font-weight:600;color:#16a34a;">Forgot password?</a>
                </label>
                <div class="input-wrap">
                    <iconify-icon icon="tabler:lock" width="16" height="16"></iconify-icon>
                    <input type="password" id="password" name="password" required
                           placeholder="••••••••" autocomplete="current-password">
                </div>
            </div>
            <button type="submit" class="submit-btn">
                <iconify-icon icon="tabler:login" width="17" height="17"></iconify-icon>
                Sign In
            </button>
        </form>

        <div class="divider">or</div>

        <div class="form-footer">
            New participant? <a href="<%= ctx %>/register">Create a free account</a>
        </div>
        <a href="<%= ctx %>/verify" class="verify-link">
            <iconify-icon icon="tabler:certificate" width="14" height="14"></iconify-icon>
            Verify a Certificate
        </a>
        <a href="<%= ctx %>/" class="verify-link" style="margin-top:6px;">
            <iconify-icon icon="tabler:home" width="14" height="14"></iconify-icon>
            Back to Home
        </a>

    </div>
</div><!-- /right-panel -->

<script>
    var hints = {
        participant: 'Demo participant filled in — or use your own account',
        facilitator: 'Demo credentials filled in automatically',
        mentor:      'Demo credentials filled in automatically',
        admin:       'Demo credentials filled in automatically'
    };
    var demoCreds = {
        participant: { email: 'amina@yep.org',  password: 'Pass@1234'   },
        facilitator: { email: 'alice@yep.org',  password: 'Facil@1234'  },
        mentor:      { email: 'brian@yep.org',  password: 'Mentor@1234' },
        admin:       { email: 'admin@yep.org',  password: 'Admin@1234'  }
    };

    function selectRole(role, btn) {
        document.querySelectorAll('.role-btn').forEach(function(b){ b.classList.remove('active'); });
        btn.classList.add('active');
        document.getElementById('hintText').textContent = hints[role];
        var c = demoCreds[role];
        document.getElementById('email').value    = c.email;
        document.getElementById('password').value = c.password;
    }

</script>
</body>
</html>
