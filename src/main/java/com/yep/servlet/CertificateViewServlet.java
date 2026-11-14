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
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/**
 * CertificateViewServlet — shows the printable certificate.
 * URL: /certificate?code=YEP-XXXX-XXXX   (public, like /verify)
 */
@WebServlet("/certificate")
public class CertificateViewServlet extends BaseServlet {

    private final CertificateDAO certDAO = new CertificateDAO();
    private final UserDAO        userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String code = param(request, "code");
        if (code.isEmpty()) {
            redirect(request, response, "/verify");
            return;
        }

        try {
            Certificate cert = certDAO.findByCode(code);
            if (cert == null) {
                redirect(request, response, "/verify?code=" + URLEncoder.encode(code, StandardCharsets.UTF_8));
                return;
            }
            User participant = userDAO.findById(cert.getParticipantId());
            request.setAttribute("certificate", cert);
            request.setAttribute("participant", participant);
            forward(request, response, "/certificate.jsp");

        } catch (Exception e) {
            showError(request, response, "Could not load the certificate.", e);
        }
    }
}
