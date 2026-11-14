package com.yep.model;

import java.security.SecureRandom;
import java.time.LocalDate;

/**
 * Certificate — issued to a participant when they complete a level (FR19).
 *
 * Each certificate has a unique verification code so employers can
 * confirm its authenticity without needing a login (FR20).
 */
public class Certificate {

    public static final String TYPE_LEVEL1 = "Level1_Digital_Skills";
    public static final String TYPE_LEVEL2 = "Level2_Impact_Project";

    // Letters and digits without easily-confused ones (no 0/O, 1/I/L) — report section 6.6
    private static final String CODE_CHARS = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final SecureRandom RANDOM = new SecureRandom();

    private int certificateId;
    private int participantId;
    private String certType;
    private String verificationCode;   // unique random code for public verification
    private LocalDate issuedDate;

    // ---- Constructors ----

    public Certificate(int participantId, String certType,
                       String verificationCode, LocalDate issuedDate) {
        this.participantId    = participantId;
        this.certType         = certType;
        this.verificationCode = verificationCode;
        this.issuedDate       = issuedDate;
    }

    public Certificate(int certificateId, int participantId, String certType,
                       String verificationCode, LocalDate issuedDate) {
        this.certificateId    = certificateId;
        this.participantId    = participantId;
        this.certType         = certType;
        this.verificationCode = verificationCode;
        this.issuedDate       = issuedDate;
    }

    // ---- Business logic ----

    /** Generates a random verification code in the format YEP-XXXX-XXXX. */
    public static String generateCode() {
        StringBuilder sb = new StringBuilder("YEP-");
        for (int i = 0; i < 8; i++) {
            if (i == 4) sb.append('-');
            sb.append(CODE_CHARS.charAt(RANDOM.nextInt(CODE_CHARS.length())));
        }
        return sb.toString();
    }

    /** Human-readable name for a certificate type. */
    public static String typeLabel(String certType) {
        if (TYPE_LEVEL2.equals(certType)) return "Level Two – Impact Project";
        if (TYPE_LEVEL1.equals(certType)) return "Level One – Digital Skills";
        return certType;
    }

    public String getTypeLabel()   { return typeLabel(certType); }
    public boolean isLevelTwo()    { return TYPE_LEVEL2.equals(certType); }

    // ---- Getters ----

    public int getCertificateId()       { return certificateId; }
    public int getParticipantId()       { return participantId; }
    public String getCertType()         { return certType; }
    public String getVerificationCode() { return verificationCode; }
    public LocalDate getIssuedDate()    { return issuedDate; }

    // ---- Setters ----

    public void setCertificateId(int id)        { this.certificateId = id; }
    public void setIssuedDate(LocalDate date)   { this.issuedDate = date; }
}
