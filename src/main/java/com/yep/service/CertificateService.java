package com.yep.service;

import com.yep.dao.*;
import com.yep.model.*;
import com.yep.util.YEPException;

import java.sql.SQLException;

/**
 * CertificateService — the business rules for issuing certificates (FR19, UC-12).
 *
 * Servlets call this class instead of CertificateDAO directly, so the rules
 * are checked in exactly one place:
 *   Level One : at least 3 sessions attended and an average of at least 50%
 *   Level Two : a Level Two participant whose team project has been APPROVED
 * A participant can only receive each type of certificate once.
 */
public class CertificateService {

    private final UserDAO        userDAO        = new UserDAO();
    private final ActivityDAO    activityDAO    = new ActivityDAO();
    private final AssessmentDAO  assessmentDAO  = new AssessmentDAO();
    private final ProjectDAO     projectDAO     = new ProjectDAO();
    private final CertificateDAO certificateDAO = new CertificateDAO();
    private final AuditLogDAO    auditLog       = new AuditLogDAO();

    /**
     * Returns null if the participant may receive this certificate,
     * otherwise a short reason why not (shown to the admin, UC-12 step 2a).
     */
    public String checkEligibility(Participant p, String certType) throws SQLException {
        if (certificateDAO.alreadyIssued(p.getUserId(), certType)) {
            return "Already issued";
        }

        if (Certificate.TYPE_LEVEL1.equals(certType)) {
            int sessions = activityDAO.countAttendance(p.getUserId());
            double avg   = assessmentDAO.getAverageScore(p.getUserId());
            if (sessions < Participant.MIN_SESSIONS)
                return "Needs " + Participant.MIN_SESSIONS + " sessions (has " + sessions + ")";
            if (avg < Participant.CERTIFICATE_AVERAGE)
                return String.format("Needs %.0f%% average (has %.1f%%)", Participant.CERTIFICATE_AVERAGE, avg);
            return null;
        }

        if (Certificate.TYPE_LEVEL2.equals(certType)) {
            if (p.getVeLevel() != 2)   return "Not on Level Two";
            if (p.getTeamId() == null) return "Not in a team";
            Project project = projectDAO.findByTeam(p.getTeamId());
            if (project == null)       return "Team has no project";
            if (!Project.STATUS_APPROVED.equals(project.getStatus()))
                return "Project not approved yet";
            return null;
        }

        return "Unknown certificate type";
    }

    /**
     * Issues a certificate after checking eligibility.
     *
     * @throws YEPException if the participant does not meet the requirements
     */
    public Certificate issue(int participantId, String certType, int adminId)
            throws YEPException, SQLException {

        User user = userDAO.findById(participantId);
        if (!(user instanceof Participant participant)) {
            throw new YEPException("Certificates can only be issued to participants.");
        }

        String reason = checkEligibility(participant, certType);
        if (reason != null) {
            throw new YEPException(participant.getFullName() + " cannot receive this certificate: " + reason + ".");
        }

        Certificate cert = certificateDAO.issue(participantId, certType);
        auditLog.log(adminId, "issue_certificate",
            participant.getFullName() + " | " + cert.getTypeLabel() + " | " + cert.getVerificationCode());
        participant.sendNotification("Your YEP certificate is ready",
            "Your " + cert.getTypeLabel() + " certificate has been issued. Verification code: "
            + cert.getVerificationCode());
        return cert;
    }
}
