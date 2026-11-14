package com.yep.service;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * SampleContent — the ready-made Level One sessions used for demonstrations.
 *
 * Each session has short learning notes (kept small for low-bandwidth users)
 * and a 5-question auto-graded quiz. The topics come from the assignment
 * brief: digital literacy, AI, media literacy, critical thinking and
 * intercultural communication, plus one upcoming employability session.
 *
 * SetupServlet loads these into the database. schema.sql contains the same
 * sessions so a fresh import already has something to complete.
 */
public final class SampleContent {

    private SampleContent() { }

    /** One sample session with its quiz. Each question row is {text, A, B, C, D, correct letter}. */
    public static final class SessionContent {
        public final String title, topic, description, notes, dateTime;
        public final int durationMins;
        public final boolean lowBandwidth;
        public final String[][] questions;

        SessionContent(String title, String topic, String description, String dateTime,
                       int durationMins, boolean lowBandwidth, String notes, String[][] questions) {
            this.title = title;           this.topic = topic;
            this.description = description;
            this.dateTime = dateTime;     this.durationMins = durationMins;
            this.lowBandwidth = lowBandwidth;
            this.notes = notes;           this.questions = questions;
        }
    }

    public static final List<SessionContent> SESSIONS = List.of(

        new SessionContent(
            "Introduction to Digital Literacy and Online Safety", "Digital Literacy",
            "The basics of using the internet well: finding reliable information, strong passwords and staying safe online.",
            "2026-10-01 09:00:00", 90, true,
            """
            What is digital literacy?
            Digital literacy means being able to find, judge, create and share information using digital tools such as a phone or computer. It is now a basic skill for school, work and business in East Africa, where most people go online through their phones.

            Finding reliable information
            • Check who wrote it. Official sites (for example .go.ug or .ac.ke) and known organisations are more reliable than unknown pages.
            • Check the date. Old information can be wrong today.
            • Compare at least two sources before you believe or share something.

            Strong passwords
            • Use at least 8 characters with letters, numbers and symbols. A short phrase is easy to remember and hard to guess.
            • Never use the same password everywhere, and never share it — not even with a friend.
            • Turn on two-step verification for email, WhatsApp and mobile money.

            Common scams
            Messages that say "You have won!", ask you to "confirm your PIN", or push you to act quickly are usually scams. Banks and mobile-money providers will never ask for your PIN.

            Saving data
            Use Wi-Fi when you can, download notes instead of streaming video, and close apps running in the background.
            """,
            new String[][] {
                {"Which password is the strongest?", "123456", "your first name", "Kampala2026", "Blue!Mango7Rain", "D"},
                {"A message says you won a prize and asks for your mobile-money PIN. What should you do?",
                 "Send the PIN quickly before the offer ends", "Ignore or report it — providers never ask for your PIN",
                 "Forward it to friends", "Reply asking for more details", "B"},
                {"What is the best way to check if information online is reliable?",
                 "See how many likes it has", "Compare it with at least two trusted sources",
                 "Trust it if it has a picture", "Believe it if a friend shared it", "B"},
                {"What does two-step verification do?",
                 "Makes your phone faster", "Adds a second check, such as an SMS code, when you log in",
                 "Lets two people share one account", "Deletes old passwords", "B"},
                {"Which habit helps you save mobile data?",
                 "Streaming every video in HD", "Leaving many apps running", "Downloading notes on Wi-Fi to read later",
                 "Turning off Wi-Fi at home", "C"},
            }),

        new SessionContent(
            "AI Tools for Everyday Life: Using AI Responsibly", "AI Literacy",
            "How AI chat tools work, what they are good at, their limits, and how to use them honestly.",
            "2026-10-08 09:00:00", 60, true,
            """
            What is AI?
            Artificial Intelligence (AI) tools such as ChatGPT, Gemini or Copilot learn patterns from very large amounts of text and images. They predict a likely answer — they do not "know" things the way a person does.

            What AI is good at
            • Brainstorming ideas and drafting text
            • Explaining a topic in simpler words
            • Summarising long documents and translating

            Limits you must remember
            • AI can "hallucinate": it may give confident answers that are completely wrong, including fake facts and fake references.
            • It may be out of date or not know local information about your district or country.
            • It can repeat unfair bias that exists in the data it learned from.

            Using AI responsibly
            1. Always check important facts with a reliable source.
            2. Never paste private information (ID numbers, passwords, other people's personal data) into an AI tool.
            3. Be honest: say when and how you used AI. On YEP every Impact Project includes an AI-use declaration.
            4. Use AI to help your thinking, not to replace it. You are responsible for the final work.
            """,
            new String[][] {
                {"What does it mean when an AI tool \"hallucinates\"?",
                 "It stops working", "It gives a confident answer that is false", "It refuses to answer", "It runs out of data", "B"},
                {"Which of these should you NEVER paste into an AI chat tool?",
                 "A question about photosynthesis", "A request to summarise a public article",
                 "Your national ID number and passwords", "A list of business ideas to improve", "C"},
                {"Why must YEP teams include an AI-use declaration with their project?",
                 "To be honest about how AI tools were used", "Because AI is not allowed at all",
                 "So the mentor can give extra marks", "To make the project longer", "A"},
                {"An AI tool gives you a statistic about youth unemployment in Uganda. What should you do?",
                 "Use it immediately", "Check it against a reliable source such as UBOS",
                 "Round the number up", "Ask the AI if it is sure and then use it", "B"},
                {"Which task is AI generally GOOD at?",
                 "Knowing today's local prices without any data", "Making final hiring decisions alone",
                 "Brainstorming ideas and drafting text", "Guaranteeing facts are correct", "C"},
            }),

        new SessionContent(
            "Spotting Fake News and Deepfakes", "Media Literacy",
            "How false information spreads on WhatsApp and social media, and simple checks before you share.",
            "2026-10-15 10:00:00", 75, true,
            """
            Why it matters
            False information spreads fastest on WhatsApp groups and social media, especially during elections, health scares and emergencies. Sharing it — even by mistake — can cause real harm.

            Types of false content
            • Misinformation: false, but shared by someone who believes it.
            • Disinformation: false, and created on purpose to mislead.
            • Deepfakes: AI-made videos, voices or photos that show people saying or doing things they never did.

            The SIFT check (before you share)
            S – Stop. Notice how the message makes you feel. Strong anger or fear is a warning sign.
            I – Investigate the source. Who posted it first? Is it a real news organisation?
            F – Find better coverage. Do trusted media (e.g. NTV, Daily Monitor, BBC) report the same thing?
            T – Trace claims, quotes and pictures to the original. A reverse image search shows if a photo is old or from another country.

            Signs of a deepfake
            Strange blinking, blurry edges around the face, lips not matching the words, or a voice that sounds flat.

            Golden rule: if you are not sure, do not share.
            """,
            new String[][] {
                {"What is the difference between misinformation and disinformation?",
                 "There is no difference", "Disinformation is false information created on purpose to mislead",
                 "Misinformation is always true", "Disinformation is only found in newspapers", "B"},
                {"What does the \"S\" in the SIFT check stand for?", "Share", "Search", "Stop", "Save", "C"},
                {"A shocking video of a politician spreads on WhatsApp. Which is a sign it may be a deepfake?",
                 "It was shared by many people", "Lips do not match the words and the face edges look blurry",
                 "It is in colour", "It is shorter than one minute", "B"},
                {"How can you check whether a photo is old or from another country?",
                 "Zoom in on it", "Do a reverse image search", "Ask the person who sent it", "Check how many people forwarded it", "B"},
                {"You are not sure whether a message is true. What is the best action?",
                 "Share it with a warning", "Share it only in family groups", "Do not share it until you have checked", "Change a few words and share it", "C"},
            }),

        new SessionContent(
            "Critical Thinking for the Digital Age", "Critical Thinking",
            "Asking good questions, separating facts from opinions and avoiding common thinking traps.",
            "2026-10-22 09:00:00", 60, false,
            """
            What is critical thinking?
            Critical thinking means carefully judging information and arguments before you accept them. It is one of the skills employers in East Africa say they need most.

            Facts and opinions
            • A fact can be checked and proved, for example "Uganda's 2024 census counted about 45 million people."
            • An opinion is a belief or feeling, for example "Kampala is the best city in Africa."
            Good arguments use facts as evidence for their opinions.

            Five useful questions
            1. Who is saying this, and what do they gain?
            2. What is the evidence?
            3. Is anything important missing?
            4. Are there other explanations?
            5. What would change my mind?

            Common thinking traps
            • Confirmation bias: only believing information that agrees with what you already think.
            • Bandwagon: "Everyone believes it, so it must be true."
            • Hasty generalisation: judging a whole group from one or two examples.
            • Correlation is not causation: two things happening together does not prove one caused the other.
            """,
            new String[][] {
                {"Which statement is a FACT rather than an opinion?",
                 "Football is the most exciting sport", "Lake Victoria borders Uganda, Kenya and Tanzania",
                 "Online learning is boring", "Nairobi has the best food", "B"},
                {"Only reading news that agrees with what you already believe is called…",
                 "Confirmation bias", "Critical thinking", "Media literacy", "Fact-checking", "A"},
                {"\"Everyone in my group says this cure works, so it must be true.\" This is an example of…",
                 "Strong evidence", "The bandwagon trap", "A scientific study", "Correlation", "B"},
                {"Ice-cream sales and drowning both rise in hot weather. What can we conclude?",
                 "Ice cream causes drowning", "Drowning causes ice-cream sales",
                 "They happen together, but that does not prove one causes the other", "Hot weather is not important", "C"},
                {"Which question is MOST useful when judging a claim?",
                 "How many emojis does it have?", "What is the evidence, and who benefits?",
                 "Is it written in English?", "How long is the message?", "B"},
            }),

        new SessionContent(
            "Working Across Cultures in East Africa", "Intercultural Communication",
            "Communicating and working well in teams with youth from different countries, languages and backgrounds.",
            "2026-10-29 09:00:00", 60, false,
            """
            Why it matters for YEP
            Level Two teams mix youth from Uganda, Kenya, Tanzania, Rwanda, Burundi and other EAC countries. Different cultures bring better ideas — but only if the team communicates well.

            Differences you may notice
            • Language: English, Kiswahili, French and local languages. Speak clearly, avoid slang, and check that people understood.
            • Directness: some people say "no" directly, others prefer polite, indirect answers.
            • Time: some groups treat meeting times strictly, others more flexibly. Agree on team rules early.
            • Respect: greetings, titles and how people address elders differ between communities.

            Good habits in a cross-country team
            1. Listen actively: let people finish, then summarise what you heard.
            2. Ask, don't assume: "How is this done in your country?"
            3. Agree on how and when you will meet, and which tools to use (WhatsApp, email, YEP).
            4. Share tasks fairly and give everyone a chance to speak.
            5. Disagree with ideas, not with people.

            Stereotypes
            A stereotype is a fixed, simple idea about a whole group ("people from X are lazy"). Stereotypes are unfair and stop teams from seeing each person's real strengths.
            """,
            new String[][] {
                {"What is \"active listening\"?",
                 "Talking more than others", "Letting people finish and then summarising what you heard",
                 "Listening to music while working", "Only listening to the team leader", "B"},
                {"A teammate's answers are often indirect. What is the best response?",
                 "Assume they are hiding something", "Ignore their ideas",
                 "Ask politely and check understanding, since communication styles differ", "Report them to the mentor", "C"},
                {"Which of these is a stereotype?",
                 "\"Grace is good at design.\"", "\"Our team meets on Tuesdays.\"",
                 "\"All people from one country are lazy.\"", "\"Kiswahili is spoken in Tanzania.\"", "C"},
                {"What should a new cross-country team agree on early?",
                 "Nothing — it is better to be flexible", "Meeting times, tools and how tasks are shared",
                 "Who is the most important member", "Which country is best", "B"},
                {"What does \"disagree with ideas, not with people\" mean?",
                 "Never disagree", "Criticise the suggestion respectfully, not the person who made it",
                 "Only agree with the leader", "Stop talking to people you disagree with", "B"},
            }),

        new SessionContent(
            "Building Your Online Portfolio", "Employability",
            "Show employers what you can do: CVs, LinkedIn and simple portfolio websites. (Upcoming session.)",
            "2026-12-03 14:00:00", 60, true,
            """
            Why a portfolio?
            A certificate shows what you learned; a portfolio shows what you can DO. Employers and universities increasingly look online before an interview.

            What to include
            • A short profile: who you are and the work you want.
            • 3–5 examples of your work: a project, a poster, a small website, a report, photos of something you built.
            • Your YEP certificates — with their verification codes, so employers can check them.

            Where to publish
            • LinkedIn profile (free)
            • A free page on Google Sites or GitHub Pages
            • A neat PDF you can send on WhatsApp or email

            Keep it professional
            Use a clear photo, check spelling, and remove anything you would not want an employer to see.
            """,
            new String[][] {
                {"What is the main purpose of a portfolio?",
                 "To list your hobbies", "To show real examples of what you can do", "To replace your ID", "To store passwords", "B"},
                {"Why include the verification code of your YEP certificate?",
                 "It looks nice", "So employers can confirm the certificate is genuine", "It is required by law", "To get extra points", "B"},
                {"How many work examples are recommended?", "None", "Exactly one", "About 3–5", "At least 50", "C"},
                {"Which is a free place to publish a portfolio?", "Google Sites", "A paid TV advert", "A bank account", "Mobile money", "A"},
                {"Before sharing your portfolio you should…",
                 "Add as many selfies as possible", "Check spelling and remove anything unprofessional",
                 "Include your passwords", "Make it at least 100 pages", "B"},
            })
    );

    /**
     * Inserts all sample sessions and their quiz questions for the given facilitator.
     *
     * @return the new activity IDs, in the same order as SESSIONS
     */
    public static List<Integer> insertAll(Connection conn, int facilitatorId) throws SQLException {
        String sessionSql = "INSERT INTO activities (title, topic, description, session_date, duration_mins, " +
                            "facilitator_id, low_bandwidth, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        String questionSql = "INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, " +
                             "option_c, option_d, correct_option) VALUES (?, ?, ?, ?, ?, ?, ?)";
        List<Integer> ids = new ArrayList<>();

        for (SessionContent s : SESSIONS) {
            int activityId;
            try (PreparedStatement ps = conn.prepareStatement(sessionSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, s.title);
                ps.setString(2, s.topic);
                ps.setString(3, s.description);
                ps.setTimestamp(4, Timestamp.valueOf(s.dateTime));
                ps.setInt(5, s.durationMins);
                ps.setInt(6, facilitatorId);
                ps.setBoolean(7, s.lowBandwidth);
                ps.setString(8, s.notes.strip());
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    keys.next();
                    activityId = keys.getInt(1);
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(questionSql)) {
                for (String[] q : s.questions) {
                    ps.setInt(1, activityId);
                    for (int i = 0; i < 6; i++) ps.setString(i + 2, q[i]);
                    ps.executeUpdate();
                }
            }
            ids.add(activityId);
        }
        return ids;
    }
}
