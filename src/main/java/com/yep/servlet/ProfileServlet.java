package com.yep.servlet;

import com.yep.dao.AuditLogDAO;
import com.yep.dao.CertificateDAO;
import com.yep.dao.UserDAO;
import com.yep.model.Participant;
import com.yep.model.User;
import com.yep.util.PasswordUtil;
import com.yep.util.ValidationUtil;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * ProfileServlet — "My Profile" for every role.
 *
 *   GET  /profile                         → view all personal data we store (privacy: right to access)
 *   POST action=saveProfile               → update phone; participants also edit their portfolio (FR23)
 *   POST action=changePassword            → change password (needs the current password)
 *   POST action=deleteAccount             → participant deletes their personal data (privacy: right to erasure)
 */
@WebServlet("/profile")
public class ProfileServlet extends BaseServlet {

    private final UserDAO        userDAO  = new UserDAO();
    private final CertificateDAO certDAO  = new CertificateDAO();
    private final AuditLogDAO    auditLog = new AuditLogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = currentUser(request);
        if (user == null) { redirect(request, response, "/login"); return; }
        try {
            if (user instanceof Participant) {
                request.setAttribute("certificates", certDAO.findByParticipant(user.getUserId()));
            }
            forward(request, response, "/profile.jsp");
        } catch (Exception e) {
            showError(request, response, "Could not load your profile.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = currentUser(request);
        if (user == null) { redirect(request, response, "/login"); return; }

        try {
            switch (param(request, "action")) {
                case "saveProfile"    -> saveProfile(request, user);
                case "changePassword" -> changePassword(request, user);
                case "deleteAccount"  -> { deleteAccount(request, response, user); return; }
                default -> { }
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        } catch (Exception e) {
            log("Profile update failed", e);
            flash(request, "error", "Your changes could not be saved because of a system problem.");
        }
        redirect(request, response, "/profile");
    }

    private void saveProfile(HttpServletRequest request, User user) throws Exception {
        String phone = param(request, "phone");
        if (!ValidationUtil.isValidPhone(phone)) throw new YEPException("Phone number should be 9–15 digits.");
        userDAO.updateContact(user.getUserId(), phone.isEmpty() ? null : phone);

        // Polymorphism in action: only a Participant has a portfolio
        if (user instanceof Participant p) {
            String bio    = param(request, "bio");
            String skills = param(request, "skills");
            String link   = param(request, "portfolioLink");

            if (bio.length() > 500)    throw new YEPException("The short bio can be at most 500 characters.");
            if (skills.length() > 300) throw new YEPException("Skills can be at most 300 characters.");
            // Only real web links, so nobody can save a "javascript:" link (XSS)
            if (!link.isEmpty() && !(link.startsWith("https://") || link.startsWith("http://")) || link.length() > 300)
                throw new YEPException("The portfolio link must start with https:// (or leave it empty).");

            p.setDistrict(emptyToNull(param(request, "district")));
            p.setBio(emptyToNull(bio));
            p.setSkills(emptyToNull(skills));
            p.setPortfolioLink(emptyToNull(link));
            p.setPortfolioPublic(request.getParameter("portfolioPublic") != null);
            userDAO.updatePortfolio(p);
        }
        flash(request, "success", "Your profile has been saved.");
    }

    private void changePassword(HttpServletRequest request, User user) throws Exception {
        String current = request.getParameter("current");
        String next    = request.getParameter("password");
        String confirm = request.getParameter("confirm");

        if (current == null || !PasswordUtil.verify(current, user.getPasswordHashForVerification()))
            throw new YEPException("Your current password is not correct.");
        if (!PasswordUtil.isStrongEnough(next))
            throw new YEPException("The new password must be 8+ characters with letters and numbers.");
        if (!next.equals(confirm))
            throw new YEPException("The two new passwords do not match.");

        userDAO.updatePassword(user.getUserId(), PasswordUtil.hash(next));
        auditLog.log(user.getUserId(), "change_password", null);
        flash(request, "success", "Your password has been changed.");
    }

    private void deleteAccount(HttpServletRequest request, HttpServletResponse response, User user) throws Exception {
        if (!(user instanceof Participant)) {
            flash(request, "error", "Staff accounts are closed by the administrator.");
            redirect(request, response, "/profile");
            return;
        }
        String password = request.getParameter("confirmPassword");
        if (password == null || !PasswordUtil.verify(password, user.getPasswordHashForVerification())) {
            flash(request, "error", "Password not correct — your account was NOT deleted.");
            redirect(request, response, "/profile");
            return;
        }

        userDAO.anonymise(user.getUserId());
        auditLog.log(user.getUserId(), "delete_my_data", "Participant #" + user.getUserId() + " erased their personal data");

        request.getSession().invalidate();
        flash(request, "success", "Your personal data has been deleted and your account closed.");
        redirect(request, response, "/login");
    }

    private static String emptyToNull(String value) {
        return value.isEmpty() ? null : value;
    }
}
