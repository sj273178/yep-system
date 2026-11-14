package com.yep.servlet;

import com.yep.dao.ActivityDAO;
import com.yep.dao.AssessmentDAO;
import com.yep.dao.AuditLogDAO;
import com.yep.dao.QuizDAO;
import com.yep.model.Activity;
import com.yep.model.Facilitator;
import com.yep.model.Question;
import com.yep.model.Quiz;
import com.yep.util.YEPException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * QuestionServlet — facilitators build the auto-graded quiz for their session (FR10).
 *
 *   GET  /questions?activityId=X            → list questions and the "add question" form
 *   POST /questions action=add              → add a multiple-choice question
 *   POST /questions action=delete           → remove a question
 *
 * FAIRNESS RULE: once any participant has taken the quiz the questions are
 * locked, so everybody is marked on exactly the same questions.
 */
@WebServlet("/questions")
public class QuestionServlet extends BaseServlet {

    public static final int MAX_QUESTIONS = 10;

    private final ActivityDAO   activityDAO   = new ActivityDAO();
    private final AssessmentDAO assessmentDAO = new AssessmentDAO();
    private final QuizDAO       quizDAO       = new QuizDAO();
    private final AuditLogDAO   auditLog      = new AuditLogDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Facilitator facilitator = requireRole(request, response, Facilitator.class);
        if (facilitator == null) return;

        try {
            Activity activity = findOwnActivity(facilitator, intParam(request, "activityId"));
            request.setAttribute("activity", activity);
            request.setAttribute("quiz",     quizDAO.findByActivity(activity.getActivityId()));
            request.setAttribute("locked",   assessmentDAO.anyQuizTaken(activity.getActivityId()));
            forward(request, response, "/facilitator/questions.jsp");

        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
            redirect(request, response, "/sessions");
        } catch (Exception e) {
            showError(request, response, "Could not load the quiz questions.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Facilitator facilitator = requireRole(request, response, Facilitator.class);
        if (facilitator == null) return;

        String back = "/sessions";
        try {
            Activity activity = findOwnActivity(facilitator, intParam(request, "activityId"));
            back = "/questions?activityId=" + activity.getActivityId();

            if (assessmentDAO.anyQuizTaken(activity.getActivityId()))
                throw new YEPException("Participants have already taken this quiz, so its questions can no longer be changed.");

            if ("delete".equals(param(request, "action"))) {
                quizDAO.delete(intParam(request, "questionId"), activity.getActivityId());
                flash(request, "success", "Question removed.");
            } else {
                addQuestion(request, activity);
                auditLog.log(facilitator.getUserId(), "add_question", "\"" + activity.getTitle() + "\"");
                flash(request, "success", "Question added.");
            }
        } catch (YEPException e) {
            flash(request, "error", e.getMessage());
        } catch (Exception e) {
            log("Could not change quiz questions", e);
            flash(request, "error", "Could not save the change. Please try again.");
        }
        redirect(request, response, back);
    }

    private void addQuestion(HttpServletRequest request, Activity activity) throws Exception {
        Quiz quiz = quizDAO.findByActivity(activity.getActivityId());
        if (quiz.getSize() >= MAX_QUESTIONS)
            throw new YEPException("A quiz can have at most " + MAX_QUESTIONS + " questions.");

        String text = param(request, "questionText");
        String a = param(request, "optionA"), b = param(request, "optionB");
        String c = param(request, "optionC"), d = param(request, "optionD");
        String correct = param(request, "correctOption").toUpperCase();

        if (text.length() < 5 || text.length() > 500)
            throw new YEPException("The question must be 5–500 characters.");
        for (String option : new String[] {a, b, c, d}) {
            if (option.isEmpty() || option.length() > 200)
                throw new YEPException("Please fill in all four answer options (up to 200 characters each).");
        }
        if (!Question.isValidLetter(correct))
            throw new YEPException("Please choose which option (A–D) is correct.");

        quizDAO.add(new Question(0, activity.getActivityId(), text, a, b, c, d, correct.charAt(0)));
    }

    private Activity findOwnActivity(Facilitator facilitator, int activityId) throws Exception {
        Activity activity = activityDAO.findById(activityId);
        if (activity == null || activity.getFacilitatorId() != facilitator.getUserId())
            throw new YEPException("You can only edit quizzes for your own sessions.");
        return activity;
    }
}
