package com.yep.util;

/**
 * YEPException — a custom checked exception for YEP business rule violations.
 *
 * Using a custom exception type lets servlets distinguish between a
 * normal Java error (NullPointerException, SQLException) and a
 * deliberate business-rule rejection (e.g. "age must be 18-35").
 * The servlet can then show a friendly message to the user instead
 * of a raw stack trace.
 */
public class YEPException extends Exception {

    public YEPException(String message) {
        super(message);
    }

    public YEPException(String message, Throwable cause) {
        super(message, cause);
    }
}
