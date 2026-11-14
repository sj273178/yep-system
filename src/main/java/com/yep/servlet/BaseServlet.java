package com.yep.servlet;

import com.yep.model.User;
import com.yep.util.FlashMessage;
import com.yep.util.SessionUtil;
import com.yep.util.ValidationUtil;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * BaseServlet — the parent class of every YEP servlet.
 *
 * INHERITANCE: Before this class existed, every servlet had its own copy
 * of "get the logged-in user or redirect to login". Now the shared code is
 * written once here and each servlet simply "extends BaseServlet".
 *
 * ABSTRACTION: The class is abstract because it is never used on its own;
 * Tomcat only creates the concrete subclasses (LoginServlet, AdminServlet...).
 */
public abstract class BaseServlet extends HttpServlet {

    // ----------------------------------------------------------------
    // Authentication and role-based access control (NFR04)
    // ----------------------------------------------------------------

    /**
     * Returns the logged-in user (re-loaded from the database so it is never
     * stale), or null if nobody is logged in.
     */
    protected User currentUser(HttpServletRequest request) {
        try {
            return SessionUtil.getRefreshedUser(request);
        } catch (Exception e) {
            log("Could not refresh the logged-in user", e);
            return null;
        }
    }

    /**
     * Returns the logged-in user if they have the required role. Otherwise
     * redirects (to login, or to their own dashboard) and returns null.
     *
     * The generic type T means the caller gets back the exact subclass:
     *     Facilitator f = requireRole(req, resp, Facilitator.class);
     * so no casting is needed.
     */
    protected <T extends User> T requireRole(HttpServletRequest request, HttpServletResponse response,
                                             Class<T> role) throws IOException {
        User user = currentUser(request);
        if (user == null) {
            redirect(request, response, "/login");
            return null;
        }
        if (!role.isInstance(user)) {
            flash(request, "error", "You do not have permission to open that page.");
            redirect(request, response, user.getDashboardMenu());   // polymorphism
            return null;
        }
        return role.cast(user);
    }

    // ----------------------------------------------------------------
    // Navigation helpers
    // ----------------------------------------------------------------

    /** Redirects to a path inside this web application, e.g. "/admin?page=users". */
    protected void redirect(HttpServletRequest request, HttpServletResponse response, String path)
            throws IOException {
        response.sendRedirect(request.getContextPath() + path);
    }

    /** Forwards to a JSP page (the URL in the browser does not change). */
    protected void forward(HttpServletRequest request, HttpServletResponse response, String jsp)
            throws ServletException, IOException {
        request.getRequestDispatcher(jsp).forward(request, response);
    }

    /** Stores a one-time message that the next page will display. */
    protected void flash(HttpServletRequest request, String type, String text) {
        request.getSession(true).setAttribute(FlashMessage.SESSION_KEY, new FlashMessage(type, text));
    }

    /**
     * Handles an unexpected error: the technical details go to the server
     * log, the user sees a friendly message (we never show stack traces or
     * SQL errors to users — NFR04).
     */
    protected void showError(HttpServletRequest request, HttpServletResponse response,
                             String friendlyMessage, Exception e) throws ServletException, IOException {
        log(friendlyMessage, e);
        request.setAttribute("error", friendlyMessage);
        forward(request, response, "/error.jsp");
    }

    // ----------------------------------------------------------------
    // Request parameter helpers
    // ----------------------------------------------------------------

    /** Returns a trimmed request parameter, or "" if it is missing. */
    protected String param(HttpServletRequest request, String name) {
        return ValidationUtil.clean(request.getParameter(name));
    }

    /** Reads a whole-number parameter, throwing a friendly YEPException if it is not a number. */
    protected int intParam(HttpServletRequest request, String name) throws YEPException {
        try {
            return Integer.parseInt(param(request, name));
        } catch (NumberFormatException e) {
            throw new YEPException("Invalid or missing value for " + name + ".");
        }
    }
}
