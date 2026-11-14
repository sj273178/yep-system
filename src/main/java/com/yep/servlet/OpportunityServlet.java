package com.yep.servlet;

import com.yep.dao.AuditLogDAO;
import com.yep.dao.OpportunityDAO;
import com.yep.model.Admin;
import com.yep.model.Opportunity;
import com.yep.util.ValidationUtil;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;

/**
 * OpportunityServlet — internships and team challenges from partners (FR24).
 *
 *   GET  /opportunities                → anyone can browse (no login needed)
 *   POST action=create / action=delete → admin only, on behalf of partner organisations
 */
@WebServlet("/opportunities")
public class OpportunityServlet extends BaseServlet {

    private final OpportunityDAO opportunityDAO = new OpportunityDAO();
    private final AuditLogDAO    auditLog       = new AuditLogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            currentUser(request);   // refreshes the session copy so the menu is right
            request.setAttribute("opportunities", opportunityDAO.findAll());
            forward(request, response, "/opportunities.jsp");
        } catch (Exception e) {
            showError(request, response, "Could not load the opportunities.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Admin admin = requireRole(request, response, Admin.class);
        if (admin == null) return;

        try {
            if ("delete".equals(param(request, "action"))) {
                opportunityDAO.delete(intParam(request, "opportunityId"));
                auditLog.log(admin.getUserId(), "delete_opportunity", "#" + param(request, "opportunityId"));
                flash(request, "success", "The opportunity was removed.");
            } else {
                create(request, admin);
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        } catch (Exception e) {
            log("Opportunity action failed", e);
            flash(request, "error", "The opportunity could not be saved because of a system problem.");
        }
        redirect(request, response, "/opportunities");
    }

    private void create(HttpServletRequest request, Admin admin) throws Exception {
        String title   = param(request, "title");
        String org     = param(request, "organisation");
        String type    = param(request, "type");
        String desc    = param(request, "description");
        String country = param(request, "country");
        String link    = param(request, "applyLink");

        if (title.length() < 5 || title.length() > 200) throw new YEPException("Please enter a title (5–200 characters).");
        if (org.length() < 2 || org.length() > 150)     throw new YEPException("Please enter the partner organisation.");
        if (!Opportunity.TYPE_INTERNSHIP.equals(type) && !Opportunity.TYPE_CHALLENGE.equals(type))
            throw new YEPException("Please choose Internship or Team Challenge.");
        if (desc.length() < 20)                          throw new YEPException("Please describe the opportunity (at least 20 characters).");
        if (!country.isEmpty() && !ValidationUtil.isEacCountry(country)) throw new YEPException("Please choose a valid country.");
        if (!link.isEmpty() && !(link.startsWith("https://") || link.startsWith("http://")))
            throw new YEPException("The application link must start with https://");

        LocalDate deadline;
        try {
            deadline = LocalDate.parse(param(request, "deadline"));
        } catch (DateTimeParseException e) {
            throw new YEPException("Please choose a deadline date.");
        }
        if (deadline.isBefore(LocalDate.now())) throw new YEPException("The deadline cannot be in the past.");

        opportunityDAO.create(title, org, type, desc, country.isEmpty() ? null : country,
                              deadline, link.isEmpty() ? null : link, admin.getUserId());
        auditLog.log(admin.getUserId(), "post_opportunity", title + " (" + org + ")");
        flash(request, "success", "\"" + title + "\" has been posted.");
    }
}
