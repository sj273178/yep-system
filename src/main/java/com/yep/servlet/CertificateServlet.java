package com.yep.servlet;

import com.yep.dao.CertificateDAO;
import com.yep.dao.UserDAO;
import com.yep.model.Certificate;
import com.yep.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * CertificateServlet — public certificate verification page (FR20).
 *
 * This page does NOT require login — anyone (e.g. an employer) can check a
 * certificate using its code. For privacy (report section 8.2) only the
 * name, country, award and date are shown.
 *
 *   GET /verify            → show the verification form
 *   GET /verify?code=XYZ   → look up the certificate and show GENUINE / NOT FOUND
 */
@WebServlet("/verify")
public class CertificateServlet extends BaseServlet {

    private final CertificateDAO certDAO = new CertificateDAO();
    private final UserDAO        userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String code = param(request, "code");

        if (!code.isEmpty()) {
            try {
                Certificate cert = certDAO.findByCode(code);
                if (cert != null) {
                    User participant = userDAO.findById(cert.getParticipantId());
                    request.setAttribute("certificate", cert);
                    request.setAttribute("participantName", participant != null ? participant.getFullName() : "Unknown");
                    request.setAttribute("valid", true);
                } else {
                    request.setAttribute("valid", false);
                }
            } catch (Exception e) {
                log("Certificate verification failed", e);
                request.setAttribute("error", "Could not verify the certificate right now. Please try again.");
            }
        }
        forward(request, response, "/verify.jsp");
    }
}
