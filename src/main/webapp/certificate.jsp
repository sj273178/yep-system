<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.yep.model.Certificate,com.yep.model.User,com.yep.util.ValidationUtil,com.yep.util.DateUtil" %>
<%--
    Printable certificate. CertificateViewServlet loads the certificate and
    the participant, then forwards here (the JSP does no database work).
--%>
<%
    Certificate cert = (Certificate) request.getAttribute("certificate");
    User participant = (User) request.getAttribute("participant");
    if (cert == null) {
        response.sendRedirect(request.getContextPath() + "/verify");
        return;
    }

    String name     = ValidationUtil.escapeHtml(participant != null ? participant.getFullName() : "Unknown");
    String country  = ValidationUtil.escapeHtml(participant != null ? participant.getCountry() : "");
    String code     = ValidationUtil.escapeHtml(cert.getVerificationCode());
    String codeUrl  = java.net.URLEncoder.encode(cert.getVerificationCode(), "UTF-8");

    boolean isLevel2 = cert.isLevelTwo();
    String awardTitle = isLevel2
        ? "Certificate of Achievement — Level Two Impact Project"
        : "Certificate of Completion — Level One Digital Skills";
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Certificate — <%= name %> — YEP</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Playfair+Display:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Inter', sans-serif;
            background: #f0f4f0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 32px 16px 48px;
        }

        /* ---- Toolbar (screen only) ---- */
        .toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            width: 100%;
            max-width: 900px;
            margin-bottom: 24px;
            flex-wrap: wrap;
            gap: 10px;
        }
        .toolbar a, .toolbar button {
            font-family: 'Inter', sans-serif;
            font-size: .85rem;
            font-weight: 600;
            padding: 9px 18px;
            border-radius: 8px;
            cursor: pointer;
            border: none;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-back    { background: white; border: 1.5px solid #d1d5db; color: #374151; }
        .btn-print   { background: #16a34a; color: white; }
        .btn-back, .btn-print { display: inline-flex; align-items: center; gap: 6px; }
        .btn-print:hover { background: #15803d; }

        /* ---- Certificate wrapper ---- */
        .cert-wrapper {
            width: 100%;
            max-width: 900px;
            background: white;
            border-radius: 4px;
            box-shadow: 0 20px 60px rgba(0,0,0,.18);
            overflow: hidden;
        }

        /* ---- Outer border decoration ---- */
        .cert-outer {
            padding: 12px;
            background: linear-gradient(135deg, #14532d, #166534, #15803d, #16a34a, #15803d, #166534, #14532d);
        }

        /* ---- Inner certificate body ---- */
        .cert-inner {
            background: #fffef8;
            border: 2px solid #d4af37;
            padding: 48px 56px;
            position: relative;
            overflow: hidden;
        }

        /* ---- Watermark ---- */
        .cert-inner::before {
            content: 'YEP';
            position: absolute;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%) rotate(-20deg);
            font-size: 14rem;
            font-weight: 900;
            color: rgba(22,163,74,.04);
            font-family: 'Playfair Display', serif;
            pointer-events: none;
            white-space: nowrap;
        }

        /* ---- Corner ornaments ---- */
        .corner {
            position: absolute;
            width: 60px; height: 60px;
            border-color: #d4af37;
            border-style: solid;
        }
        .corner-tl { top: 16px; left: 16px;  border-width: 3px 0 0 3px; }
        .corner-tr { top: 16px; right: 16px; border-width: 3px 3px 0 0; }
        .corner-bl { bottom: 16px; left: 16px;  border-width: 0 0 3px 3px; }
        .corner-br { bottom: 16px; right: 16px; border-width: 0 3px 3px 0; }

        /* ---- Header ---- */
        .cert-header {
            text-align: center;
            margin-bottom: 32px;
            position: relative;
        }
        .cert-logo-row {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 14px;
            margin-bottom: 8px;
        }
        .cert-logo-mark {
            width: 52px; height: 52px;
            background: linear-gradient(135deg, #14532d, #16a34a);
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            color: white; font-size: 1.4rem; font-weight: 900;
            font-family: 'Playfair Display', serif;
            box-shadow: 0 4px 12px rgba(22,163,74,.3);
        }
        .cert-org-name {
            font-family: 'Playfair Display', serif;
            font-size: 1.3rem;
            font-weight: 700;
            color: #14532d;
            line-height: 1.2;
        }
        .cert-org-sub {
            font-size: .75rem;
            color: #6b7280;
            letter-spacing: .12em;
            text-transform: uppercase;
            font-weight: 600;
        }

        /* ---- Divider ---- */
        .ornament-line {
            display: flex;
            align-items: center;
            gap: 10px;
            margin: 20px 0;
        }
        .ornament-line::before, .ornament-line::after {
            content: '';
            flex: 1;
            height: 1px;
            background: linear-gradient(90deg, transparent, #d4af37, transparent);
        }
        .ornament-diamond {
            width: 8px; height: 8px;
            background: #d4af37;
            transform: rotate(45deg);
            flex-shrink: 0;
        }

        /* ---- Presents ---- */
        .cert-presents {
            text-align: center;
            font-size: .8rem;
            letter-spacing: .18em;
            text-transform: uppercase;
            color: #9ca3af;
            font-weight: 600;
            margin-bottom: 8px;
        }

        /* ---- Award title ---- */
        .cert-award-title {
            text-align: center;
            font-family: 'Playfair Display', serif;
            font-size: 1.9rem;
            font-weight: 900;
            color: #14532d;
            line-height: 1.25;
            margin-bottom: 28px;
        }

        /* ---- Recipient name ---- */
        .cert-recipient-label {
            text-align: center;
            font-size: .75rem;
            letter-spacing: .18em;
            text-transform: uppercase;
            color: #9ca3af;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .cert-recipient-name {
            text-align: center;
            font-family: 'Playfair Display', serif;
            font-size: 2.6rem;
            font-weight: 700;
            color: #111827;
            border-bottom: 2px solid #d4af37;
            display: inline-block;
            padding-bottom: 6px;
            min-width: 60%;
        }
        .cert-recipient-row {
            text-align: center;
            margin-bottom: 28px;
        }

        /* ---- Description ---- */
        .cert-description {
            text-align: center;
            color: #374151;
            font-size: .9rem;
            line-height: 1.8;
            max-width: 560px;
            margin: 0 auto 32px;
        }

        /* ---- Skills pills ---- */
        .cert-skills {
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 8px;
            margin-bottom: 36px;
        }
        .skill-pill {
            background: #dcfce7;
            color: #14532d;
            border: 1px solid #86efac;
            border-radius: 20px;
            padding: 4px 14px;
            font-size: .78rem;
            font-weight: 600;
            display: inline-flex; align-items: center; gap: 6px;
        }

        /* ---- Signatures row ---- */
        .cert-signatures {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 20px;
            margin-top: 36px;
            padding-top: 24px;
            border-top: 1px solid #e5e7eb;
        }
        .sig-block { text-align: center; }
        .sig-line {
            border-bottom: 1.5px solid #374151;
            margin-bottom: 6px;
            height: 36px;
        }
        .sig-title {
            font-size: .72rem;
            text-transform: uppercase;
            letter-spacing: .1em;
            color: #6b7280;
            font-weight: 600;
        }
        .sig-name {
            font-size: .85rem;
            font-weight: 700;
            color: #111827;
            margin-top: 2px;
        }

        /* ---- Footer strip ---- */
        .cert-footer {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 28px;
            padding-top: 16px;
            border-top: 1px solid #f3f4f6;
            flex-wrap: wrap;
            gap: 10px;
        }
        .cert-meta {
            font-size: .72rem;
            color: #9ca3af;
            line-height: 1.6;
        }
        .cert-meta strong { color: #374151; }
        .cert-qr-placeholder {
            width: 60px; height: 60px;
            border: 2px solid #e5e7eb;
            border-radius: 6px;
            display: flex; align-items: center; justify-content: center;
            color: #14532d;
        }

        /* ---- Valid ribbon ---- */
        .valid-ribbon {
            position: absolute;
            top: 24px; right: -18px;
            background: #16a34a;
            color: white;
            font-size: .65rem;
            font-weight: 700;
            letter-spacing: .12em;
            text-transform: uppercase;
            padding: 4px 24px;
            transform: rotate(45deg);
            transform-origin: center;
        }

        /* ---- Print ---- */
        @media print {
            body { background: white; padding: 0; }
            .toolbar { display: none; }
            .cert-wrapper { box-shadow: none; max-width: 100%; }
            .cert-outer { padding: 8px; }
        }

        @media (max-width: 600px) {
            .cert-inner { padding: 32px 24px; }
            .cert-award-title { font-size: 1.3rem; }
            .cert-recipient-name { font-size: 1.8rem; }
            .cert-signatures { grid-template-columns: 1fr; gap: 16px; }
        }
    </style>
<script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>
</head>
<body>

    <div class="toolbar">
        <a href="<%= ctx %>/verify?code=<%= codeUrl %>" class="btn-back"><iconify-icon icon="tabler:arrow-left" width="15" height="15"></iconify-icon> Back to Verification</a>
        <button class="btn-print" onclick="window.print()"><iconify-icon icon="tabler:printer" width="16" height="16"></iconify-icon> Print Certificate</button>
    </div>

    <div class="cert-wrapper">
        <div class="cert-outer">
            <div class="cert-inner">

                <!-- Corner ornaments -->
                <div class="corner corner-tl"></div>
                <div class="corner corner-tr"></div>
                <div class="corner corner-bl"></div>
                <div class="corner corner-br"></div>

                <!-- Valid ribbon -->
                <div style="position:absolute;top:0;right:0;overflow:hidden;width:80px;height:80px;">
                    <div class="valid-ribbon">Verified</div>
                </div>

                <!-- Header -->
                <div class="cert-header">
                    <div class="cert-logo-row">
                        <div class="cert-logo-mark">Y</div>
                        <div>
                            <div class="cert-org-name">Youth Empowerment Project</div>
                            <div class="cert-org-sub">East African Community Programme</div>
                        </div>
                    </div>
                </div>

                <div class="ornament-line"><div class="ornament-diamond"></div></div>

                <div class="cert-presents">This is to certify that</div>

                <!-- Recipient -->
                <div class="cert-recipient-row">
                    <div class="cert-recipient-name"><%= name %></div>
                </div>

                <div class="cert-presents" style="margin-top:-16px;margin-bottom:16px;">
                    from <%= country %>
                </div>

                <!-- Award -->
                <div class="cert-award-title"><%= awardTitle %></div>

                <!-- Description -->
                <div class="cert-description">
                    <% if (isLevel2) { %>
                        has successfully completed the <strong>Youth Empowerment Project Level Two
                        Virtual Exchange Programme</strong>, demonstrating outstanding leadership,
                        cross-cultural collaboration, and the development of a practical
                        Impact Project addressing community challenges in East Africa.
                    <% } else { %>
                        has successfully completed the <strong>Youth Empowerment Project Level One
                        Virtual Exchange Programme</strong>, demonstrating proficiency in digital
                        literacy, critical thinking, media literacy, artificial intelligence
                        awareness, and intercultural communication skills.
                    <% } %>
                </div>

                <!-- Skills earned -->
                <div class="cert-skills">
                    <% if (isLevel2) { %>
                        <span class="skill-pill"><iconify-icon icon="tabler:heart-handshake" width="14" height="14"></iconify-icon> Cross-Cultural Collaboration</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:bulb" width="14" height="14"></iconify-icon> Impact Project Development</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:brain" width="14" height="14"></iconify-icon> Critical Thinking</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:world" width="14" height="14"></iconify-icon> Community Problem Solving</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:speakerphone" width="14" height="14"></iconify-icon> Leadership</span>
                    <% } else { %>
                        <span class="skill-pill"><iconify-icon icon="tabler:device-laptop" width="14" height="14"></iconify-icon> Digital Literacy</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:robot" width="14" height="14"></iconify-icon> AI Awareness</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:news" width="14" height="14"></iconify-icon> Media Literacy</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:world" width="14" height="14"></iconify-icon> Intercultural Communication</span>
                        <span class="skill-pill"><iconify-icon icon="tabler:brain" width="14" height="14"></iconify-icon> Critical Thinking</span>
                    <% } %>
                </div>

                <div class="ornament-line"><div class="ornament-diamond"></div></div>

                <!-- Signatures -->
                <div class="cert-signatures">
                    <div class="sig-block">
                        <div class="sig-line"></div>
                        <div class="sig-title">Programme Director</div>
                        <div class="sig-name">YEP Secretariat</div>
                    </div>
                    <div class="sig-block" style="display:flex;flex-direction:column;align-items:center;justify-content:flex-end;">
                        <div style="margin-bottom:4px;color:#b8860b;"><iconify-icon icon="tabler:award-filled" width="36" height="36"></iconify-icon></div>
                        <div style="font-size:.7rem;color:#9ca3af;text-transform:uppercase;letter-spacing:.1em;font-weight:600;">
                            Date Issued
                        </div>
                        <div style="font-weight:700;color:#111827;font-size:.9rem;margin-top:2px;">
                            <%= DateUtil.formatLong(cert.getIssuedDate()) %>
                        </div>
                    </div>
                    <div class="sig-block">
                        <div class="sig-line"></div>
                        <div class="sig-title">Lead Facilitator</div>
                        <div class="sig-name">East Africa Hub</div>
                    </div>
                </div>

                <!-- Footer -->
                <div class="cert-footer">
                    <div class="cert-meta">
                        <strong>Certificate No:</strong> <%= String.format("%05d", cert.getCertificateId()) %><br>
                        <strong>Verification Code:</strong> <%= code %><br>
                        <strong>Verify at:</strong> <%= request.getServerName() + (request.getServerPort() == 80 ? "" : ":" + request.getServerPort()) + ctx %>/verify
                    </div>
                    <div class="cert-qr-placeholder" title="Verification QR"><iconify-icon icon="tabler:qrcode" width="40" height="40"></iconify-icon></div>
                </div>

            </div><!-- cert-inner -->
        </div><!-- cert-outer -->
    </div><!-- cert-wrapper -->

</body>
</html>
