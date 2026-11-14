package com.yep.servlet;

import com.yep.dao.*;
import com.yep.model.*;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * SessionServlet — Level One learning sessions (activities).
 *
 *   GET  /sessions                     → participants browse sessions, facilitators manage them
 *   GET  /sessions?id=X                → participant: session page (notes, join, quiz)
 *   GET  /sessions?id=X&download=notes → the learning notes as a small text file (low-data option)
 *   GET  /sessions?action=create       → create-session form (facilitator, FR07)
 *   POST /sessions action=create       → save a new session (FR07)
 *   POST /sessions action=attend       → participant joins; attendance + points (FR08, FR09)
 *   POST /sessions action=takeQuiz     → participant submits the quiz; auto-graded (FR10, FR11)
 *
 * HOW A PARTICIPANT COMPLETES A SESSION:
 *   1. open the session and read the notes / follow the recording
 *   2. join by video, audio-only or notes  → attendance and 10 points
 *   3. take the 5-question quiz (one attempt) → score saved as an Assessment
 *   After 3 completed sessions with a 60%+ average they are eligible for Level Two (FR12).
 */
@WebServlet("/sessions")
public class SessionServlet extends BaseServlet {

    private static final List<String> MODES = List.of("video", "audio", "download");

    private final ActivityDAO   activityDAO   = new ActivityDAO();
    private final AssessmentDAO assessmentDAO = new AssessmentDAO();
    private final QuizDAO       quizDAO       = new QuizDAO();
    private final UserDAO       userDAO       = new UserDAO();
    private final AuditLogDAO   auditLog      = new AuditLogDAO();

    // ================================================================
    // GET
    // ================================================================

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = currentUser(request);
        if (user == null) { redirect(request, response, "/login"); return; }

        try {
            String id = param(request, "id");

            if (!id.isEmpty() && "notes".equals(param(request, "download"))) {
                downloadNotes(request, response, intParam(request, "id"));

            } else if (user instanceof Facilitator) {
                if ("create".equals(param(request, "action"))) {
                    forward(request, response, "/facilitator/create-session.jsp");
                    return;
                }
                request.setAttribute("sessions",      activityDAO.findAll());
                request.setAttribute("attendees",     activityDAO.countAttendeesPerActivity());
                request.setAttribute("questionCount", quizDAO.countQuestionsPerActivity());
                forward(request, response, "/facilitator/sessions.jsp");

            } else if (user instanceof Participant participant) {
                if (!id.isEmpty()) {
                    showSession(request, response, participant, intParam(request, "id"));
                } else {
                    request.setAttribute("sessions",      activityDAO.findAll());
                    request.setAttribute("attendedModes", activityDAO.findAttendanceModes(participant.getUserId()));
                    request.setAttribute("quizScores",    assessmentDAO.findQuizScores(participant.getUserId()));
                    request.setAttribute("questionCount", quizDAO.countQuestionsPerActivity());
                    forward(request, response, "/participant/sessions.jsp");
                }

            } else {
                // Mentors and admins do not use the sessions pages
                redirect(request, response, user.getDashboardMenu());
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
            redirect(request, response, "/sessions");
        } catch (Exception e) {
            showError(request, response, "Could not load the sessions. Please try again.", e);
        }
    }

    /** The session page: notes, join options and the quiz (or the quiz result). */
    private void showSession(HttpServletRequest request, HttpServletResponse response,
                             Participant participant, int activityId) throws Exception {
        Activity activity = requireActivity(activityId);
        String mode = activityDAO.findAttendanceModes(participant.getUserId()).get(activityId);

        request.setAttribute("activity",   activity);
        request.setAttribute("attendedMode", mode);
        request.setAttribute("quiz",       quizDAO.findByActivity(activityId));
        request.setAttribute("quizResult", assessmentDAO.find(participant.getUserId(), activityId, "quiz"));
        forward(request, response, "/participant/session.jsp");
    }

    /** Sends the learning notes as a small .txt file — the "Download notes" option (NFR02). */
    private void downloadNotes(HttpServletRequest request, HttpServletResponse response, int activityId)
            throws Exception {
        Activity activity = requireActivity(activityId);
        String text = activity.getTitle() + "\n" + "=".repeat(activity.getTitle().length()) + "\n"
                    + "YEP Level One session — " + activity.getTopic() + "\n\n"
                    + (activity.getNotes() != null ? activity.getNotes() : "No notes have been added yet.") + "\n";

        response.setContentType("text/plain;charset=UTF-8");
        response.setHeader("Content-Disposition",
            "attachment; filename=\"YEP-session-" + activityId + "-notes.txt\"");
        response.getOutputStream().write(text.getBytes(StandardCharsets.UTF_8));
    }

    // ================================================================
    // POST
    // ================================================================

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = param(request, "action");
        try {
            switch (action) {
                case "create" -> {
                    Facilitator f = requireRole(request, response, Facilitator.class);
                    if (f != null) createSession(request, response, f);
                }
                case "attend" -> {
                    Participant p = requireRole(request, response, Participant.class);
                    if (p != null) markAttendance(request, response, p);
                }
                case "takeQuiz" -> {
                    Participant p = requireRole(request, response, Participant.class);
                    if (p != null) takeQuiz(request, response, p);
                }
                default -> redirect(request, response, "/sessions");
            }
        } catch (Exception e) {
            showError(request, response, "That action could not be completed. Please try again.", e);
        }
    }

    /** FR07 — validates and saves a new Level One session, then opens the quiz editor. */
    private void createSession(HttpServletRequest request, HttpServletResponse response,
                               Facilitator facilitator) throws Exception {
        try {
            String title        = param(request, "title");
            String topic        = param(request, "topic");
            String description  = param(request, "description");
            String notes        = param(request, "notes");
            String recordingUrl = param(request, "recordingUrl");

            if (title.length() < 3 || title.length() > 200)
                throw new YEPException("Session title must be 3–200 characters.");
            if (topic.isEmpty() || topic.length() > 200)
                throw new YEPException("Please enter a topic.");
            if (!recordingUrl.isEmpty() && !recordingUrl.matches("https?://\\S+"))
                throw new YEPException("The recording link must start with http:// or https://");

            LocalDateTime sessionDate;
            try {
                sessionDate = LocalDateTime.parse(param(request, "sessionDate"));   // "2026-10-01T09:00"
            } catch (DateTimeParseException e) {
                throw new YEPException("Please choose a valid date and time.");
            }

            int duration = intParam(request, "durationMins");
            if (duration < 15 || duration > 480)
                throw new YEPException("Duration must be between 15 and 480 minutes.");

            Activity activity = new Activity(title, topic, description.isEmpty() ? null : description,
                sessionDate, duration, facilitator.getUserId(), "on".equals(request.getParameter("lowBandwidth")));
            activity.setNotes(notes.isEmpty() ? null : notes);
            activity.setRecordingUrl(recordingUrl.isEmpty() ? null : recordingUrl);
            int id = activityDAO.create(activity);

            auditLog.log(facilitator.getUserId(), "create_session", "\"" + title + "\" (ID " + id + ")");
            flash(request, "success", "Session \"" + title + "\" created. Now add the quiz questions participants will answer.");
            redirect(request, response, "/questions?activityId=" + id);

        } catch (YEPException e) {
            request.setAttribute("error", e.getMessage());
            forward(request, response, "/facilitator/create-session.jsp");
        }
    }

    /** FR08/FR09 — records attendance in the chosen mode and awards participation points. */
    private void markAttendance(HttpServletRequest request, HttpServletResponse response,
                                Participant participant) throws Exception {
        String back = "/sessions";
        try {
            Activity activity = requireActivity(intParam(request, "activityId"));
            back = "/sessions?id=" + activity.getActivityId();

            if (!activity.hasStarted())
                throw new YEPException("This session has not started yet. You can join from its start time.");

            String mode = param(request, "mode");
            if (!MODES.contains(mode)) mode = "video";

            if (!activityDAO.recordAttendance(activity.getActivityId(), participant.getUserId(), mode)) {
                flash(request, "info", "You have already joined this session.");
            } else {
                userDAO.addPoints(participant.getUserId(), Participant.POINTS_PER_SESSION);
                auditLog.log(participant.getUserId(), "attend_session", "\"" + activity.getTitle() + "\" via " + mode);
                flash(request, "success", "Attendance recorded — you earned " + Participant.POINTS_PER_SESSION
                    + " points. Now take the quiz below to complete the session.");
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        }
        redirect(request, response, back);
    }

    /** FR10/FR11 — marks the quiz, saves the score (one attempt) and reports progress. */
    private void takeQuiz(HttpServletRequest request, HttpServletResponse response,
                          Participant participant) throws Exception {
        String back = "/sessions";
        try {
            Activity activity = requireActivity(intParam(request, "activityId"));
            back = "/sessions?id=" + activity.getActivityId();

            if (!activityDAO.hasAttended(activity.getActivityId(), participant.getUserId()))
                throw new YEPException("Join the session (video, audio or notes) before taking the quiz.");

            Quiz quiz = quizDAO.findByActivity(activity.getActivityId());

            // Read the answers: each radio button group is named "q<questionId>"
            Map<Integer, String> answers = new HashMap<>();
            for (Question q : quiz.getQuestions()) {
                answers.put(q.getQuestionId(), param(request, "q" + q.getQuestionId()));
            }

            int correct    = quiz.grade(answers);            // throws if a question was skipped
            double percent = quiz.toPercent(correct);

            // The score is recorded against the session's facilitator, who set the quiz
            Assessment result = new Assessment(participant.getUserId(), activity.getActivityId(), percent, "quiz",
                "Online quiz: " + correct + "/" + quiz.getSize() + " correct", activity.getFacilitatorId());

            if (!assessmentDAO.saveQuizAttempt(result))
                throw new YEPException("You have already taken this quiz. Each quiz can only be taken once.");

            auditLog.log(participant.getUserId(), "take_quiz",
                "\"" + activity.getTitle() + "\" " + correct + "/" + quiz.getSize());

            // Tell the participant where they stand for Level Two
            int sessions = activityDAO.countAttendance(participant.getUserId());
            double avg   = assessmentDAO.getAverageScore(participant.getUserId());
            String progress = participant.isEligibleForPromotion(sessions, avg)
                ? " You now meet the Level Two requirements — the YEP admin will review your promotion."
                : participant.getVeLevel() == 1
                    ? String.format(" Progress: %d/%d sessions, %.0f%% average (need %.0f%%).",
                        Math.min(sessions, Participant.MIN_SESSIONS), Participant.MIN_SESSIONS, avg, Participant.PROMOTION_AVERAGE)
                    : "";

            flash(request, percent >= Quiz.PASS_MARK ? "success" : "warning",
                String.format("You scored %d/%d (%.0f%%) — %s.%s",
                    correct, quiz.getSize(), percent, Participant.computeGrade(percent), progress));

        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        }
        redirect(request, response, back);
    }

    private Activity requireActivity(int activityId) throws Exception {
        Activity activity = activityDAO.findById(activityId);
        if (activity == null) throw new YEPException("That session no longer exists.");
        return activity;
    }
}
