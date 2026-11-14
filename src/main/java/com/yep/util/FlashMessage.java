package com.yep.util;

import java.io.Serializable;

/**
 * FlashMessage — a one-time message ("Session created", "Score must be 0–100")
 * shown on the next page the user sees.
 *
 * After a POST the servlet redirects (Post/Redirect/Get pattern) so that
 * refreshing the page does not submit the form twice. Because a redirect
 * starts a new request, the message is kept in the HTTP session until the
 * shared navigation bar (nav.jspf) displays it and removes it.
 */
public class FlashMessage implements Serializable {

    public static final String SESSION_KEY = "flash";

    private final String type;   // success, error, info or warning (matches the CSS alert-* classes)
    private final String text;

    public FlashMessage(String type, String text) {
        this.type = type;
        this.text = text;
    }

    public String getType() { return type; }
    public String getText() { return text; }
}
