package com.yep.servlet;

import com.yep.model.User;
import com.yep.util.FlashMessage;
import com.yep.util.SessionUtil;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * AuthFilter — protects the role folders (/participant, /facilitator,
 * /mentor, /admin) so their JSP pages cannot be opened by the wrong user.
 *
 * HOW A FILTER WORKS:
 *   Tomcat runs the filter BEFORE the requested page. If the check passes
 *   we call chain.doFilter() to continue to the page; otherwise we redirect
 *   and the page never runs.
 *
 * The filter also refreshes the session copy of the user from the database,
 * so dashboards always show the current level, team and active status.
 */
@WebFilter(urlPatterns = {"/participant/*", "/facilitator/*", "/mentor/*", "/admin/*"})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;
        String ctx = request.getContextPath();

        User user;
        try {
            user = SessionUtil.getRefreshedUser(request);
        } catch (Exception e) {
            user = null;
        }

        if (user == null) {
            response.sendRedirect(ctx + "/login");
            return;
        }

        // The folder name must match the role, e.g. "/admin/users.jsp" needs role ADMIN.
        // ("/admin" on its own is the AdminServlet URL, which matches the same rule.)
        String path   = request.getServletPath();               // e.g. "/participant/dashboard.jsp"
        String folder = path.split("/")[1];                      // e.g. "participant"
        if (!folder.equalsIgnoreCase(user.getRole())) {
            request.getSession().setAttribute(FlashMessage.SESSION_KEY,
                new FlashMessage("error", "You do not have permission to open that page."));
            response.sendRedirect(ctx + user.getDashboardMenu());
            return;
        }

        chain.doFilter(req, res);
    }
}
