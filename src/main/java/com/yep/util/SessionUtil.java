package com.yep.util;

import com.yep.dao.UserDAO;
import com.yep.model.User;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

import java.sql.SQLException;

/**
 * SessionUtil — reloads the logged-in user from the database and
 * updates the session copy.
 *
 * WHY THIS IS NEEDED:
 *   When a user logs in, a snapshot of their User object is stored in
 *   the HTTP session. If an admin promotes them to Level Two or assigns
 *   them to a team, the snapshot becomes stale — it still shows Level One
 *   with no team. This method fetches the latest data from the database
 *   and replaces the stale snapshot so pages always show current info.
 *
 *   It also ends the session straight away if an admin has deactivated
 *   the account, so a deactivated user cannot keep using the system.
 */
public class SessionUtil {

    public static final String USER_KEY = "loggedInUser";

    private SessionUtil() { }

    public static User getRefreshedUser(HttpServletRequest request) throws SQLException {
        HttpSession session = request.getSession(false);
        if (session == null) return null;

        User stale = (User) session.getAttribute(USER_KEY);
        if (stale == null) return null;

        User fresh = new UserDAO().findById(stale.getUserId());

        if (fresh == null || !fresh.isActive()) {
            session.invalidate();   // account deleted or deactivated — log the user out
            return null;
        }
        session.setAttribute(USER_KEY, fresh);
        return fresh;
    }
}
