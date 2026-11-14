package com.yep.model;

/**
 * Notifiable interface — demonstrates ABSTRACTION.
 *
 * Any class that implements Notifiable promises to provide a
 * sendNotification() method. The calling code does not need to
 * know whether the notification goes by SMS, email, or both —
 * it just calls sendNotification() on any Notifiable object.
 */
public interface Notifiable {

    /**
     * Send a notification to this user.
     * Each concrete class decides how the message is delivered.
     */
    void sendNotification(String subject, String message);
}
