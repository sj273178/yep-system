package com.yep.util;

import com.yep.model.User;
import java.time.LocalDate;
import java.time.Period;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * ValidationUtil — reusable input validation methods for registration and forms.
 *
 * Keeping validation in one place means the same rules apply whether
 * the check comes from a servlet, a DAO, or a test.
 */
public class ValidationUtil {

    /** Genders accepted by the database ENUM. */
    public static final List<String> GENDERS = List.of("Male", "Female", "Other");

    /** Two-letter ISO country codes, used to build readable team names. */
    private static final Map<String, String> COUNTRY_CODES = Map.of(
        "Burundi", "BI", "DR Congo", "CD", "Kenya", "KE", "Rwanda", "RW",
        "Somalia", "SO", "South Sudan", "SS", "Tanzania", "TZ", "Uganda", "UG"
    );

    // Utility class — no objects needed
    private ValidationUtil() { }

    /** Returns true if the given country is one of the EAC member states (FR02). */
    public static boolean isEacCountry(String country) {
        if (country == null) return false;
        return Arrays.asList(User.EAC_COUNTRIES).contains(country);
    }

    /** Returns true if the person's age is between 18 and 35 inclusive (FR02). */
    public static boolean isValidAge(LocalDate dateOfBirth) {
        if (dateOfBirth == null) return false;
        int age = Period.between(dateOfBirth, LocalDate.now()).getYears();
        return age >= 18 && age <= 35;
    }

    /**
     * Returns true if the email looks valid: something@domain.tld with no spaces.
     * This is a basic check; production would also send a confirmation email.
     */
    public static boolean isValidEmail(String email) {
        if (email == null || email.isBlank() || email.contains(" ")) return false;
        int atIndex = email.indexOf('@');
        if (atIndex < 1 || atIndex != email.lastIndexOf('@')) return false;
        String domain = email.substring(atIndex + 1);
        int dot = domain.lastIndexOf('.');
        return dot > 0 && dot < domain.length() - 1;
    }

    /** Phone is optional; if given it must be 9–15 digits, optionally starting with +. */
    public static boolean isValidPhone(String phone) {
        if (phone == null || phone.isBlank()) return true;
        return phone.replace(" ", "").matches("\\+?[0-9]{9,15}");
    }

    /** Emails are stored in lower case so "Amina@YEP.org" and "amina@yep.org" are the same account. */
    public static String normaliseEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    /** Returns true if the string is not null and not blank. */
    public static boolean isNotBlank(String value) {
        return value != null && !value.isBlank();
    }

    /** Trims a value, turning null into an empty string. */
    public static String clean(String value) {
        return value == null ? "" : value.trim();
    }

    /** Returns the two-letter code for an EAC country, e.g. "Uganda" -> "UG". */
    public static String countryCode(String country) {
        return COUNTRY_CODES.getOrDefault(country, "XX");
    }

    /**
     * Sanitises a value for display in HTML to prevent XSS attacks (NFR04).
     * Replaces the five characters that have special meaning in HTML.
     */
    public static String escapeHtml(Object input) {
        if (input == null) return "";
        return input.toString()
            .replace("&",  "&amp;")
            .replace("<",  "&lt;")
            .replace(">",  "&gt;")
            .replace("\"", "&quot;")
            .replace("'",  "&#x27;");
    }
}
