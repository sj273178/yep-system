package com.yep.util;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * DateUtil — formats dates the same way on every page,
 * e.g. "Thu 1 Oct 2026, 09:00" instead of "2026-10-01T09:00".
 */
public class DateUtil {

    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("EEE d MMM yyyy, HH:mm");
    private static final DateTimeFormatter DATE      = DateTimeFormatter.ofPattern("d MMM yyyy");
    private static final DateTimeFormatter LONG_DATE = DateTimeFormatter.ofPattern("d MMMM yyyy");

    private DateUtil() { }

    public static String format(LocalDateTime dateTime) {
        return dateTime == null ? "—" : dateTime.format(DATE_TIME);
    }

    public static String format(LocalDate date) {
        return date == null ? "—" : date.format(DATE);
    }

    /** Long form used on printed certificates, e.g. "12 November 2026". */
    public static String formatLong(LocalDate date) {
        return date == null ? "" : date.format(LONG_DATE);
    }
}
