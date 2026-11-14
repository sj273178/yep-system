package com.yep.model;

/**
 * Question — one multiple-choice question in a session quiz.
 *
 * Every question has four options (A, B, C and D) and exactly one correct
 * answer. ENCAPSULATION: the correct answer is never exposed to the page
 * that shows the quiz; other classes ask isCorrect() instead.
 */
public class Question {

    public static final char[] LETTERS = {'A', 'B', 'C', 'D'};

    private int questionId;
    private int activityId;
    private String text;
    private final String[] options = new String[4];
    private char correctOption;

    public Question(int questionId, int activityId, String text,
                    String optionA, String optionB, String optionC, String optionD,
                    char correctOption) {
        this.questionId    = questionId;
        this.activityId    = activityId;
        this.text          = text;
        this.options[0]    = optionA;
        this.options[1]    = optionB;
        this.options[2]    = optionC;
        this.options[3]    = optionD;
        this.correctOption = Character.toUpperCase(correctOption);
    }

    // ---- Business logic ----

    /** Returns true if the given letter ("A".."D", any case) is the right answer. */
    public boolean isCorrect(String answer) {
        return answer != null && answer.length() == 1
            && Character.toUpperCase(answer.charAt(0)) == correctOption;
    }

    /** Returns the text of option A, B, C or D. */
    public String getOption(char letter) {
        int index = Character.toUpperCase(letter) - 'A';
        return (index >= 0 && index < 4) ? options[index] : "";
    }

    /** Checks that a letter is one of A, B, C or D. */
    public static boolean isValidLetter(String letter) {
        return letter != null && letter.length() == 1 && "ABCD".contains(letter.toUpperCase());
    }

    // ---- Getters ----

    public int getQuestionId()     { return questionId; }
    public int getActivityId()     { return activityId; }
    public String getText()        { return text; }
    public char getCorrectOption() { return correctOption; }   // used by the DAO and the answer review

    public void setQuestionId(int id) { this.questionId = id; }
}
