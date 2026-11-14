package com.yep.servlet;

import com.yep.dao.AuditLogDAO;
import com.yep.dao.UserDAO;
import com.yep.model.User;
import com.yep.util.PasswordUtil;
import com.yep.util.ValidationUtil;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.security.SecureRandom;
import java.time.LocalDateTime;

/**
 * ForgotPasswordServlet — reset a forgotten password with a one-time code (FR05).
 *
 *   Step 1  POST action=send   the user types their email; we create a random
 *                              6-digit code, store only its BCrypt HASH, and
 *                              "send" it by SMS/email (simulated).
 *   Step 2  POST action=reset  the user types the code and a new password.
 *
 * Rules: the code expires after 10 minutes and allows 3 wrong tries.
 * A successful reset also unlocks an account locked by FR04.
 */
@WebServlet("/forgot-password")
public class ForgotPasswordServlet extends BaseServlet {

    private static final int CODE_MINUTES = 10;
    private static final int MAX_TRIES    = 3;

    // Session keys used between step 1 and step 2
    private static final String KEY_USER  = "resetUserId";
    private static final String KEY_EMAIL = "resetEmail";
    private static final String KEY_TRIES = "resetTries";

    private final UserDAO      userDAO  = new UserDAO();
    private final AuditLogDAO  auditLog = new AuditLogDAO();
    private final SecureRandom random   = new SecureRandom();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // "?restart" goes back to step 1
        if (request.getParameter("restart") != null) clearReset(request.getSession());
        forward(request, response, "/forgot.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            if ("reset".equals(param(request, "action"))) {
                resetPassword(request, response);
            } else {
                sendCode(request);
                forward(request, response, "/forgot.jsp");
            }
        } catch (YEPException e) {
            request.setAttribute("error", e.getMessage());
            forward(request, response, "/forgot.jsp");
        } catch (Exception e) {
            showError(request, response, "Could not reset the password right now.", e);
        }
    }

    /** Step 1 — create and "send" the code. */
    private void sendCode(HttpServletRequest request) throws Exception {
        String email = ValidationUtil.normaliseEmail(request.getParameter("email"));
        if (!ValidationUtil.isValidEmail(email)) throw new YEPException("Please enter a valid email address.");

        HttpSession session = request.getSession();
        clearReset(session);
        session.setAttribute(KEY_EMAIL, email);

        User user = userDAO.findByEmail(email);
        if (user == null || !user.isActive()) {
            // Same screen as a real account, so nobody can find out which emails exist
            return;
        }

        String code = String.format("%06d", random.nextInt(1_000_000));
        userDAO.saveResetCode(user.getUserId(), PasswordUtil.hash(code), LocalDateTime.now().plusMinutes(CODE_MINUTES));
        user.sendNotification("YEP password reset code",
            "Your code is " + code + ". It expires in " + CODE_MINUTES + " minutes.");   // simulated SMS/email

        session.setAttribute(KEY_USER, user.getUserId());
        session.setAttribute(KEY_TRIES, 0);
        // PROTOTYPE ONLY: no real SMS/email gateway, so the code is shown on screen for the demo.
        request.setAttribute("demoCode", code);
    }

    /** Step 2 — check the code and save the new password. */
    private void resetPassword(HttpServletRequest request, HttpServletResponse response) throws Exception {
        HttpSession session = request.getSession();
        String code     = param(request, "code");
        String password = request.getParameter("password");
        String confirm  = request.getParameter("confirm");

        if (session.getAttribute(KEY_EMAIL) == null) throw new YEPException("Please start again and enter your email.");
        if (!PasswordUtil.isStrongEnough(password))  throw new YEPException("The new password must be 8+ characters with letters and numbers.");
        if (!password.equals(confirm))               throw new YEPException("The two passwords do not match.");

        Integer userId = (Integer) session.getAttribute(KEY_USER);
        Object[] saved = userId == null ? null : userDAO.findResetCode(userId);
        if (saved == null) throw new YEPException("That code is not correct.");

        if (LocalDateTime.now().isAfter((LocalDateTime) saved[1])) {
            clearReset(session);
            throw new YEPException("The code has expired. Please request a new one.");
        }

        if (!code.matches("\\d{6}") || !PasswordUtil.verify(code, (String) saved[0])) {
            int tries = (Integer) session.getAttribute(KEY_TRIES) + 1;
            session.setAttribute(KEY_TRIES, tries);
            if (tries >= MAX_TRIES) {
                userDAO.saveResetCode(userId, null, LocalDateTime.now());   // cancel the code
                clearReset(session);
                throw new YEPException("Too many wrong codes. Please request a new code.");
            }
            throw new YEPException("That code is not correct. " + (MAX_TRIES - tries) + " tries left.");
        }

        userDAO.updatePassword(userId, PasswordUtil.hash(password));   // also unlocks the account
        auditLog.log(userId, "password_reset", "Password reset with a one-time code");
        clearReset(session);
        flash(request, "success", "Your password has been changed. You can now sign in.");
        redirect(request, response, "/login");
    }

    private void clearReset(HttpSession session) {
        session.removeAttribute(KEY_USER);
        session.removeAttribute(KEY_EMAIL);
        session.removeAttribute(KEY_TRIES);
    }
}
