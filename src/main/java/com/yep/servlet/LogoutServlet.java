package com.yep.servlet;

import com.yep.dao.AuditLogDAO;
import com.yep.model.User;
import com.yep.util.SessionUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * LogoutServlet — ends the user's session and returns to the login page.
 */
@WebServlet("/logout")
public class LogoutServlet extends BaseServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);
        if (session != null) {
            User user = (User) session.getAttribute(SessionUtil.USER_KEY);
            if (user != null) new AuditLogDAO().log(user.getUserId(), "logout", null);
            // Destroy the session so the stored User object is removed from the server
            session.invalidate();
        }

        flash(request, "info", "You have been signed out safely.");
        redirect(request, response, "/login");
    }
}
