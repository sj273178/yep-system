package com.yep.servlet;

import com.yep.dao.AuditLogDAO;
import com.yep.dao.UserDAO;
import com.yep.model.Participant;
import com.yep.util.PasswordUtil;
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
 * RegisterServlet — handles the participant registration form (FR01, FR02, FR03).
 *
 * HOW SERVLETS WORK:
 *   1. The registration form has action="register" method="POST".
 *   2. When the user clicks Submit, the browser sends an HTTP POST request
 *      to /register.
 *   3. Tomcat routes that request to this servlet.
 *   4. doPost() reads the form fields, validates them, and either creates
 *      an account or shows the form again with an error message.
 *
 * Use case UC-01 alternative flow 4a: when validation fails the form keeps
 * everything the user typed (except the passwords).
 */
@WebServlet("/register")
public class RegisterServlet extends BaseServlet {

    private final UserDAO     userDAO  = new UserDAO();
    private final AuditLogDAO auditLog = new AuditLogDAO();

    /** doGet — shows the empty registration form. */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        forward(request, response, "/register.jsp");
    }

    /** doPost — validates the submitted form and creates the account. */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String fullName    = param(request, "fullName");
        String email       = ValidationUtil.normaliseEmail(request.getParameter("email"));
        String phone       = param(request, "phone");
        String password    = request.getParameter("password");
        String confirmPass = request.getParameter("confirmPassword");
        String country     = param(request, "country");
        String dobStr      = param(request, "dateOfBirth");
        String gender      = param(request, "gender");
        String district    = param(request, "district");
        String education   = param(request, "educationLevel");
        boolean disability = "on".equals(request.getParameter("hasDisability"));

        try {
            // ---- Validate inputs (FR02, FR03) ----
            if (fullName.length() < 3 || fullName.length() > 100)
                throw new YEPException("Please enter your full name (3–100 characters).");

            if (!ValidationUtil.isValidEmail(email))
                throw new YEPException("Please enter a valid email address.");

            if (!ValidationUtil.isValidPhone(phone))
                throw new YEPException("Phone number should be 9–15 digits, e.g. +256700000000.");

            if (!ValidationUtil.isEacCountry(country))
                throw new YEPException("Registration is open to East African Community countries only.");

            LocalDate dateOfBirth;
            try {
                dateOfBirth = LocalDate.parse(dobStr);
            } catch (DateTimeParseException e) {
                throw new YEPException("Please enter your date of birth.");
            }
            if (!ValidationUtil.isValidAge(dateOfBirth))
                throw new YEPException("YEP is for youth aged 18 to 35 only.");

            if (!ValidationUtil.GENDERS.contains(gender))
                throw new YEPException("Please select your gender.");

            if (!PasswordUtil.isStrongEnough(password))
                throw new YEPException("Password must be at least 8 characters and contain letters and numbers.");

            if (!password.equals(confirmPass))
                throw new YEPException("Passwords do not match.");

            if (!"on".equals(request.getParameter("consent")))
                throw new YEPException("You must consent to data processing to register.");

            if (userDAO.emailExists(email))
                throw new YEPException("An account with this email already exists. Try signing in instead.");

            // ---- Create the account ----
            Participant participant = new Participant(
                fullName, email, phone.isEmpty() ? null : phone, PasswordUtil.hash(password), country,
                dateOfBirth, gender, district.isEmpty() ? null : district, education.isEmpty() ? null : education
            );
            participant.setConsentGiven(true);
            participant.setHasDisability(disability);

            int newUserId = userDAO.createParticipant(participant);
            participant.setUserId(newUserId);

            auditLog.log(newUserId, "register", "New participant from " + country);
            participant.sendNotification("Welcome to YEP",
                "Welcome to YEP, " + fullName + "! Your participant ID is " + newUserId + ".");

            flash(request, "success", "Account created! Please sign in with your email and password.");
            redirect(request, response, "/login");

        } catch (YEPException e) {
            // Business rule violation — show the form again; the JSP refills the fields
            request.setAttribute("error", e.getMessage());
            forward(request, response, "/register.jsp");

        } catch (Exception e) {
            log("Registration failed", e);
            request.setAttribute("error", "Registration failed because of a system problem. Please try again.");
            forward(request, response, "/register.jsp");
        }
    }
}
