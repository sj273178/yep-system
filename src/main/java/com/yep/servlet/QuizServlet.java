package com.yep.servlet;

import com.yep.dao.ActivityDAO;
import com.yep.dao.AssessmentDAO;
import com.yep.dao.AuditLogDAO;
import com.yep.dao.QuizDAO;
import com.yep.dao.UserDAO;
import com.yep.model.Activity;
import com.yep.model.Assessment;
import com.yep.model.Facilitator;
import com.yep.model.Participant;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

/**
 * QuizServlet — facilitators record scores by hand (FR10).
 *
 * Sessions with an online quiz are marked automatically (see SessionServlet),
 * so for those the facilitator only records PARTICIPATION scores here.
 * Sessions without an online quiz can still have a quiz score entered by hand.
 *
 *   GET  /quiz                 → choose one of your sessions
 *   GET  /quiz?activityId=X    → score the participants who attended session X
 *   POST /quiz                 → save (or update) a score
 *
 * A facilitator can only score their own sessions, and only participants
 * who actually attended that session.
 */
@WebServlet("/quiz")
public class QuizServlet extends BaseServlet {

    private static final List<String> TYPES = List.of("quiz", "participation");

    private final AssessmentDAO assessmentDAO = new AssessmentDAO();
    private final ActivityDAO   activityDAO   = new ActivityDAO();
    private final UserDAO       userDAO       = new UserDAO();
    private final AuditLogDAO   auditLog      = new AuditLogDAO();
    private final QuizDAO       quizDAO       = new QuizDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Facilitator facilitator = requireRole(request, response, Facilitator.class);
        if (facilitator == null) return;

        try {
            request.setAttribute("activities", activityDAO.findByFacilitator(facilitator.getUserId()));

            String idStr = request.getParameter("activityId");
            if (idStr != null && !idStr.isBlank()) {
                Activity activity = findOwnActivity(facilitator, intParam(request, "activityId"));
                request.setAttribute("activity",       activity);
                request.setAttribute("attendees",      userDAO.findAttendees(activity.getActivityId()));
                request.setAttribute("existingScores", assessmentDAO.findByActivity(activity.getActivityId()));
                request.setAttribute("hasOnlineQuiz",  !quizDAO.findByActivity(activity.getActivityId()).isEmpty());
            }
            forward(request, response, "/facilitator/quiz.jsp");

        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
            redirect(request, response, "/quiz");
        } catch (Exception e) {
            showError(request, response, "Could not load the assessment page.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Facilitator facilitator = requireRole(request, response, Facilitator.class);
        if (facilitator == null) return;

        String back = "/quiz";
        try {
            Activity activity = findOwnActivity(facilitator, intParam(request, "activityId"));
            back = "/quiz?activityId=" + activity.getActivityId();

            int participantId = intParam(request, "participantId");
            String type       = param(request, "type");
            String comment    = param(request, "comment");

            double score;
            try {
                score = Double.parseDouble(param(request, "score"));
            } catch (NumberFormatException e) {
                throw new YEPException("Please enter a score.");
            }
            if (score < 0 || score > 100)
                throw new YEPException("Score must be between 0 and 100.");
            if (!TYPES.contains(type))
                throw new YEPException("Please choose quiz or participation.");
            if ("quiz".equals(type) && !quizDAO.findByActivity(activity.getActivityId()).isEmpty())
                throw new YEPException("This session has an online quiz that is marked automatically. "
                    + "Record a participation score instead.");

            // Only participants who attended this session can be scored
            Participant participant = userDAO.findAttendees(activity.getActivityId()).stream()
                .filter(p -> p.getUserId() == participantId)
                .findFirst()
                .orElseThrow(() -> new YEPException("That participant did not attend this session."));

            Assessment assessment = new Assessment(participantId, activity.getActivityId(), score,
                type, comment.isEmpty() ? null : comment, facilitator.getUserId());
            boolean created = assessmentDAO.saveOrUpdate(assessment);

            auditLog.log(facilitator.getUserId(), "record_score",
                participant.getFullName() + " | " + activity.getTitle() + " | " + type + " " + score);
            flash(request, "success", (created ? "Score saved for " : "Score updated for ")
                + participant.getFullName() + ".");

        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        } catch (Exception e) {
            log("Could not save score", e);
            flash(request, "error", "Could not save the score. Please try again.");
        }
        redirect(request, response, back);
    }

    /** Loads a session and makes sure it belongs to this facilitator. */
    private Activity findOwnActivity(Facilitator facilitator, int activityId) throws Exception {
        Activity activity = activityDAO.findById(activityId);
        if (activity == null || activity.getFacilitatorId() != facilitator.getUserId()) {
            throw new YEPException("You can only record scores for your own sessions.");
        }
        return activity;
    }
}
