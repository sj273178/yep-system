package com.yep.model;

import com.yep.util.YEPException;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Quiz — the auto-graded multiple-choice quiz that follows a Level One session.
 *
 * COMPOSITION: a Quiz HAS-A list of Questions.
 * ENCAPSULATION: the marking rules live inside grade(), so servlets never
 * work out scores themselves.
 *
 * Saving the result as an Assessment (type "quiz") means it feeds straight
 * into the participant's average, grade and Level Two eligibility (FR10–FR12).
 */
public class Quiz {

    /** Pass mark shown on the session page (wireframe, page 26). */
    public static final double PASS_MARK = 50.0;

    private final int activityId;
    private final List<Question> questions;

    public Quiz(int activityId, List<Question> questions) {
        this.activityId = activityId;
        this.questions  = new ArrayList<>(questions);
    }

    /**
     * Marks the participant's answers.
     *
     * @param answers question_id -> chosen letter ("A".."D")
     * @return the number of correct answers
     * @throws YEPException if any question was left unanswered
     */
    public int grade(Map<Integer, String> answers) throws YEPException {
        if (questions.isEmpty()) {
            throw new YEPException("This session does not have a quiz yet.");
        }
        int correct = 0;
        for (Question q : questions) {
            String answer = answers.get(q.getQuestionId());
            if (!Question.isValidLetter(answer)) {
                throw new YEPException("Please answer all " + questions.size() + " questions before submitting.");
            }
            if (q.isCorrect(answer)) correct++;
        }
        return correct;
    }

    /** Converts a number of correct answers into a percentage score (0–100). */
    public double toPercent(int correct) {
        return questions.isEmpty() ? 0 : Math.round(correct * 1000.0 / questions.size()) / 10.0;
    }

    public boolean isEmpty()            { return questions.isEmpty(); }
    public int getSize()                { return questions.size(); }
    public int getActivityId()          { return activityId; }
    public List<Question> getQuestions(){ return Collections.unmodifiableList(questions); }
}
