package com.yep.servlet;

import com.yep.dao.AuditLogDAO;
import com.yep.dao.UserDAO;
import com.yep.model.User;
import com.yep.util.PasswordUtil;
import com.yep.util.SessionUtil;
import com.yep.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * LoginServlet — handles login (FR04, FR06).
 *
 * HOW SESSION WORKS:
 *   After a successful login, we store the User object in the HTTP session.
 *   The session is a server-side storage area linked to the browser by a
 *   cookie called JSESSIONID. As long as that cookie exists and the session
 *   has not expired, the user stays logged in.
 *
 * ACCOUNT LOCKOUT (FR04):
 *   After 3 failed attempts the account is locked. We track this in the
 *   database so the counter survives server restarts. An admin can unlock it.
 *
 * GENERIC ERROR MESSAGE (report section 8.1):
 *   A wrong email and a wrong password both show "Invalid email or password"
 *   so attackers cannot find out which emails are registered.
 */
@WebServlet("/login")
public class LoginServlet extends BaseServlet {

    private static final String INVALID = "Invalid email or password.";

    private final UserDAO     userDAO  = new UserDAO();
    private final AuditLogDAO auditLog = new AuditLogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // If already logged in, skip the login page and go to the dashboard
        User user = currentUser(request);
        if (user != null) {
            redirect(request, response, user.getDashboardMenu());
            return;
        }
        forward(request, response, "/login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email    = ValidationUtil.normaliseEmail(request.getParameter("email"));
        String password = request.getParameter("password");

        try {
            if (email.isEmpty() || password == null || password.isEmpty()) {
                showLoginError(request, response, "Please enter your email and password.");
                return;
            }

            User user = userDAO.findByEmail(email);

            // Case 1: email not found (same message as a wrong password)
            if (user == null) {
                showLoginError(request, response, INVALID);
                return;
            }

            // Case 2: account locked after too many failures (FR04)
            if (user.isLocked()) {
                showLoginError(request, response,
                    "This account is locked after 3 failed attempts. Use \"Forgot password?\" to reset it, or contact the YEP administrator.");
                return;
            }

            // Case 3: account deactivated by admin (FR22)
            if (!user.isActive()) {
                showLoginError(request, response,
                    "This account has been deactivated. Please contact the YEP administrator.");
                return;
            }

            // Case 4: wrong password
            if (!PasswordUtil.verify(password, user.getPasswordHashForVerification())) {
                user.incrementFailedLogins();
                userDAO.updateFailedLogins(user.getUserId(), user.getFailedLogins());

                if (user.isLocked()) {
                    auditLog.log(user.getUserId(), "account_locked", "3 failed login attempts");
                    showLoginError(request, response,
                        "Too many failed attempts — this account is now locked. Use \"Forgot password?\" to reset it, or contact the YEP administrator.");
                } else {
                    showLoginError(request, response, INVALID);
                }
                return;
            }

            // ---- Login successful ----
            userDAO.updateFailedLogins(user.getUserId(), 0);
            user.resetFailedLogins();
            auditLog.log(user.getUserId(), "login", "Signed in from " + request.getRemoteAddr());

            // Invalidate any old session and create a new one (prevents session fixation)
            HttpSession oldSession = request.getSession(false);
            if (oldSession != null) oldSession.invalidate();

            HttpSession session = request.getSession(true);
            session.setAttribute(SessionUtil.USER_KEY, user);

            // Each subclass returns its own dashboard (polymorphism, FR06)
            redirect(request, response, user.getDashboardMenu());

        } catch (Exception e) {
            log("Login failed", e);
            showLoginError(request, response,
                "We could not sign you in right now. Please check that the database is running and try again.");
        }
    }

    /** Shows the login page again with an error and the email the user typed. */
    private void showLoginError(HttpServletRequest request, HttpServletResponse response, String message)
            throws ServletException, IOException {
        request.setAttribute("error", message);
        forward(request, response, "/login.jsp");
    }
}
