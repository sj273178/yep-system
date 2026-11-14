package com.yep.servlet;

import com.yep.dao.CertificateDAO;
import com.yep.dao.UserDAO;
import com.yep.model.Certificate;
import com.yep.model.Participant;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * TalentServlet — public skills portfolios for partner employers (FR23).
 *
 *   GET /talent  → participants who CHOSE to make their portfolio visible.
 *
 * Privacy: only name, country, level, bio, skills, portfolio link and
 * certificate codes are shown — never email, phone, age or gender.
 */
@WebServlet("/talent")
public class TalentServlet extends BaseServlet {

    private final UserDAO        userDAO = new UserDAO();
    private final CertificateDAO certDAO = new CertificateDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            currentUser(request);
            List<Participant> people = userDAO.findPublicPortfolios();

            Map<Integer, List<Certificate>> certificates = new HashMap<>();
            for (Participant p : people) {
                certificates.put(p.getUserId(), certDAO.findByParticipant(p.getUserId()));
            }

            request.setAttribute("people", people);
            request.setAttribute("certificates", certificates);
            forward(request, response, "/talent.jsp");
        } catch (Exception e) {
            showError(request, response, "Could not load the talent directory.", e);
        }
    }
}
