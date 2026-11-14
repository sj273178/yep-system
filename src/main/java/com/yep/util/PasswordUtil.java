package com.yep.util;

import at.favre.lib.crypto.bcrypt.BCrypt;

/**
 * PasswordUtil — handles password hashing and verification.
 *
 * BCrypt is used because it is designed specifically for passwords:
 * it is intentionally slow (making brute-force attacks expensive) and
 * it automatically generates and stores a random salt in the hash string.
 *
 * HOW IT WORKS:
 *   hash()   — takes a plain-text password and returns a BCrypt hash string.
 *   verify() — takes a plain-text password and a stored hash and returns
 *              true if they match.
 *
 * The plain-text password never needs to be stored or retrieved.
 */
public class PasswordUtil {

    // Cost factor 12 means 2^12 = 4096 hashing rounds — secure yet fast enough
    private static final int BCRYPT_COST = 12;

    /**
     * Hashes a plain-text password using BCrypt.
     * Call this when creating or updating a user's password.
     */
    public static String hash(String plainTextPassword) {
        return BCrypt.withDefaults().hashToString(BCRYPT_COST, plainTextPassword.toCharArray());
    }

    /**
     * Verifies a plain-text password against a stored BCrypt hash.
     * Returns true if the password matches, false otherwise.
     * Call this during login.
     */
    public static boolean verify(String plainTextPassword, String storedHash) {
        BCrypt.Result result = BCrypt.verifyer().verify(
            plainTextPassword.toCharArray(), storedHash
        );
        return result.verified;
    }

    /**
     * Checks whether a password meets the minimum strength requirements (FR02):
     * - At least 8 characters
     * - Contains at least one letter
     * - Contains at least one digit
     */
    public static boolean isStrongEnough(String password) {
        if (password == null || password.length() < 8) return false;

        boolean hasLetter = false;
        boolean hasDigit  = false;

        for (char c : password.toCharArray()) {
            if (Character.isLetter(c)) hasLetter = true;
            if (Character.isDigit(c))  hasDigit  = true;
        }

        return hasLetter && hasDigit;
    }
}
