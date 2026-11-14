-- ============================================================
-- YEP (Youth Empowerment Project) Database Schema
-- Run this script in XAMPP phpMyAdmin (Import tab) or the MySQL
-- command line:   mysql -u root < schema.sql
--
-- WARNING: the script DROPS and re-creates every YEP table, so it
-- can be run again at any time to get a clean database.
-- ============================================================

CREATE DATABASE IF NOT EXISTS yep_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE yep_db;
SET NAMES utf8mb4;   -- so dashes and bullets in the sample notes import correctly

-- Drop tables in reverse dependency order so the script is re-runnable
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS opportunities;
DROP TABLE IF EXISTS team_messages;
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS certificates;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS assessments;
DROP TABLE IF EXISTS quiz_questions;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS activities;
DROP TABLE IF EXISTS participants;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS admins;
DROP TABLE IF EXISTS mentors;
DROP TABLE IF EXISTS facilitators;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- -------------------------------------------------------
-- USERS (supertype table — every account has a row here)
-- -------------------------------------------------------
CREATE TABLE users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100)  NOT NULL,
    email         VARCHAR(150)  NOT NULL UNIQUE,
    phone         VARCHAR(20),
    password_hash VARCHAR(255)  NOT NULL,
    country       VARCHAR(60)   NOT NULL,
    -- role determines which subtype table also has a row
    role          ENUM('PARTICIPANT','FACILITATOR','MENTOR','ADMIN') NOT NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    consent_given BOOLEAN       NOT NULL DEFAULT FALSE,
    -- failed_logins tracks attempts for account lockout (FR04)
    failed_logins INT           NOT NULL DEFAULT 0,
    -- forgotten-password reset (FR05): BCrypt hash of a 6-digit one-time code + expiry
    reset_code_hash VARCHAR(255),
    reset_expires   DATETIME,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------
-- PARTICIPANTS subtype
-- -------------------------------------------------------
CREATE TABLE participants (
    user_id         INT PRIMARY KEY,
    ve_level        TINYINT      NOT NULL DEFAULT 1,   -- 1 or 2
    points          INT          NOT NULL DEFAULT 0,
    team_id         INT,                                -- NULL until placed in a team
    date_of_birth   DATE         NOT NULL,
    gender          ENUM('Male','Female','Other') NOT NULL,
    district        VARCHAR(100),
    education_level VARCHAR(100),
    has_disability  BOOLEAN      NOT NULL DEFAULT FALSE,
    -- skills portfolio (FR23): only shown to employers when portfolio_public = TRUE
    bio              VARCHAR(500),
    skills           VARCHAR(300),
    portfolio_link   VARCHAR(300),
    portfolio_public BOOLEAN     NOT NULL DEFAULT FALSE,
    CHECK (ve_level IN (1, 2)),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- FACILITATORS subtype
-- -------------------------------------------------------
CREATE TABLE facilitators (
    user_id      INT PRIMARY KEY,
    organisation VARCHAR(150),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- MENTORS subtype
-- -------------------------------------------------------
CREATE TABLE mentors (
    user_id    INT PRIMARY KEY,
    expertise  VARCHAR(200),
    max_teams  INT NOT NULL DEFAULT 3,   -- FR14: a mentor guides at most 3 teams
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- ADMINS subtype (marker table — no extra columns needed)
-- -------------------------------------------------------
CREATE TABLE admins (
    user_id INT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- TEAMS (Level Two cross-country groups)
-- -------------------------------------------------------
CREATE TABLE teams (
    team_id    INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(150) NOT NULL,
    focus_area ENUM('employment','education','agriculture','health','climate','digital_inclusion') NOT NULL,
    mentor_id  INT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mentor_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Add foreign key from participants back to teams (after teams table exists)
ALTER TABLE participants
    ADD CONSTRAINT fk_participant_team
    FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE SET NULL;

-- -------------------------------------------------------
-- ACTIVITIES (Level One sessions created by facilitators)
-- -------------------------------------------------------
CREATE TABLE activities (
    activity_id       INT AUTO_INCREMENT PRIMARY KEY,
    title             VARCHAR(200) NOT NULL,
    topic             VARCHAR(200) NOT NULL,
    description       TEXT,
    session_date      DATETIME     NOT NULL,
    duration_mins     INT          NOT NULL DEFAULT 60,
    facilitator_id    INT          NOT NULL,
    low_bandwidth     BOOLEAN      NOT NULL DEFAULT FALSE,
    -- link to the video/audio recording (optional)
    recording_url     VARCHAR(500),
    -- short learning notes: the low-data "download notes" option (FR08, NFR02)
    notes             TEXT,
    FOREIGN KEY (facilitator_id) REFERENCES users(user_id)
);

-- -------------------------------------------------------
-- QUIZ QUESTIONS (auto-graded multiple-choice quiz for a session, FR10)
-- A participant's result is saved in ASSESSMENTS with type = 'quiz'.
-- -------------------------------------------------------
CREATE TABLE quiz_questions (
    question_id    INT AUTO_INCREMENT PRIMARY KEY,
    activity_id    INT          NOT NULL,
    question_text  VARCHAR(500) NOT NULL,
    option_a       VARCHAR(200) NOT NULL,
    option_b       VARCHAR(200) NOT NULL,
    option_c       VARCHAR(200) NOT NULL,
    option_d       VARCHAR(200) NOT NULL,
    correct_option CHAR(1)      NOT NULL,
    CHECK (correct_option IN ('A','B','C','D')),
    FOREIGN KEY (activity_id) REFERENCES activities(activity_id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- ATTENDANCE (which participant attended which activity)
-- -------------------------------------------------------
CREATE TABLE attendance (
    activity_id  INT  NOT NULL,
    user_id      INT  NOT NULL,
    attended_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- mode reflects the participant's bandwidth choice (FR08)
    mode         ENUM('video','audio','download') NOT NULL DEFAULT 'video',
    PRIMARY KEY (activity_id, user_id),
    FOREIGN KEY (activity_id) REFERENCES activities(activity_id),
    FOREIGN KEY (user_id)     REFERENCES users(user_id)
);

-- -------------------------------------------------------
-- ASSESSMENTS (quiz scores and participation points)
-- -------------------------------------------------------
CREATE TABLE assessments (
    assessment_id  INT AUTO_INCREMENT PRIMARY KEY,
    participant_id INT NOT NULL,
    activity_id    INT NOT NULL,
    score          DECIMAL(5,2) NOT NULL,   -- 0.00 to 100.00
    type           ENUM('quiz','participation') NOT NULL DEFAULT 'quiz',
    comment        TEXT,
    assessor_id    INT NOT NULL,            -- facilitator who gave this score
    assessed_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (score BETWEEN 0 AND 100),
    -- one score of each type per participant per session
    UNIQUE (participant_id, activity_id, type),
    FOREIGN KEY (participant_id) REFERENCES users(user_id),
    FOREIGN KEY (activity_id)    REFERENCES activities(activity_id),
    FOREIGN KEY (assessor_id)    REFERENCES users(user_id)
);

-- -------------------------------------------------------
-- PROJECTS (one Impact Project per Level Two team)
-- -------------------------------------------------------
CREATE TABLE projects (
    project_id         INT AUTO_INCREMENT PRIMARY KEY,
    team_id            INT NOT NULL UNIQUE,  -- one project per team
    title              VARCHAR(200) NOT NULL,
    problem_statement  TEXT,
    -- status tracks the review lifecycle (FR15, FR16)
    status             ENUM('draft','submitted','approved','revision_requested') NOT NULL DEFAULT 'draft',
    ai_use_declaration TEXT NOT NULL,
    mentor_feedback    TEXT,
    submitted_at       DATETIME,
    FOREIGN KEY (team_id) REFERENCES teams(team_id)
);

-- -------------------------------------------------------
-- CERTIFICATES (issued when requirements are met)
-- -------------------------------------------------------
CREATE TABLE certificates (
    certificate_id    INT AUTO_INCREMENT PRIMARY KEY,
    participant_id    INT          NOT NULL,
    -- cert_type shows which level the certificate covers (FR19)
    cert_type         ENUM('Level1_Digital_Skills','Level2_Impact_Project') NOT NULL,
    -- verification_code lets employers check the cert without logging in (FR20)
    verification_code VARCHAR(50)  NOT NULL UNIQUE,
    issued_date       DATE         NOT NULL,
    -- a participant can only receive each type of certificate once
    UNIQUE (participant_id, cert_type),
    FOREIGN KEY (participant_id) REFERENCES users(user_id)
);

-- -------------------------------------------------------
-- AUDIT LOG (records important actions — NFR12)
-- -------------------------------------------------------
CREATE TABLE audit_log (
    log_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT          NOT NULL,
    action     VARCHAR(100) NOT NULL,
    detail     VARCHAR(500),
    logged_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- -------------------------------------------------------
-- TEAM DISCUSSION (FR17) — messages can be flagged for review
-- -------------------------------------------------------
CREATE TABLE team_messages (
    message_id  INT AUTO_INCREMENT PRIMARY KEY,
    team_id     INT          NOT NULL,
    sender_id   INT          NOT NULL,
    body        VARCHAR(1000) NOT NULL,
    is_flagged  BOOLEAN      NOT NULL DEFAULT FALSE,
    flagged_by  INT,
    sent_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (team_id)   REFERENCES teams(team_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(user_id)
);

-- -------------------------------------------------------
-- PARTNER OPPORTUNITIES (FR24) — internships and challenges
-- posted by the admin on behalf of partner organisations
-- -------------------------------------------------------
CREATE TABLE opportunities (
    opportunity_id INT AUTO_INCREMENT PRIMARY KEY,
    title          VARCHAR(200) NOT NULL,
    organisation   VARCHAR(150) NOT NULL,
    opp_type       ENUM('internship','challenge') NOT NULL,
    description    TEXT         NOT NULL,
    country        VARCHAR(60),
    deadline       DATE         NOT NULL,
    apply_link     VARCHAR(300),
    posted_by      INT          NOT NULL,
    posted_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (posted_by) REFERENCES users(user_id)
);

-- -------------------------------------------------------
-- STAFF ACCOUNTS (passwords are BCrypt hashes, cost 12)
-- For full demo data (participants, sessions, scores) open
-- http://localhost:8080/yep-system/setup after deploying.
-- -------------------------------------------------------

-- Admin        admin@yep.org / Admin@1234
INSERT INTO users (full_name, email, phone, password_hash, country, role, is_active, consent_given)
VALUES ('YEP Admin', 'admin@yep.org', '+256700000001',
        '$2a$12$kS/5QiORRhzD4tsnys4t.ed3CDpinqWEdZJ7kxc7xOGE1pLCJlLaC',
        'Uganda', 'ADMIN', TRUE, TRUE);
INSERT INTO admins (user_id) VALUES (LAST_INSERT_ID());

-- Facilitator  alice@yep.org / Facil@1234
INSERT INTO users (full_name, email, phone, password_hash, country, role, is_active, consent_given)
VALUES ('Alice Kamau', 'alice@yep.org', '+254700000002',
        '$2a$12$AvdBj44xd9Je7UoXNdlX3ew7kbAPyaBI4SasbH.JkbskYdj1LvkeK',
        'Kenya', 'FACILITATOR', TRUE, TRUE);
INSERT INTO facilitators (user_id, organisation) VALUES (LAST_INSERT_ID(), 'Nairobi Tech Hub');

-- Mentor       brian@yep.org / Mentor@1234
INSERT INTO users (full_name, email, phone, password_hash, country, role, is_active, consent_given)
VALUES ('Brian Ochieng', 'brian@yep.org', '+255700000003',
        '$2a$12$4QjsvjcOmF90XtY29QvRguUqCreNvK5Q76Yja3Ml2QrT/jecnRUU6',
        'Tanzania', 'MENTOR', TRUE, TRUE);
INSERT INTO mentors (user_id, expertise) VALUES (LAST_INSERT_ID(), 'Digital Skills & Entrepreneurship');

-- -------------------------------------------------------
-- SAMPLE LEVEL ONE SESSIONS with learning notes and 5-question quizzes
-- (same content as com.yep.service.SampleContent, used by /setup).
-- A participant completes a session by joining it and taking its quiz;
-- 3 completed sessions with a 60%+ average make them eligible for Level Two.
-- -------------------------------------------------------
SET @facilitator = (SELECT user_id FROM users WHERE email = 'alice@yep.org');

-- Introduction to Digital Literacy and Online Safety
INSERT INTO activities (title, topic, description, session_date, duration_mins, facilitator_id, low_bandwidth, notes)
VALUES ('Introduction to Digital Literacy and Online Safety', 'Digital Literacy', 'The basics of using the internet well: finding reliable information, strong passwords and staying safe online.', '2026-10-01 09:00:00', 90, @facilitator, TRUE,
'What is digital literacy?
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
Use Wi-Fi when you can, download notes instead of streaming video, and close apps running in the background.');
SET @session = LAST_INSERT_ID();
INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, option_c, option_d, correct_option) VALUES
(@session, 'Which password is the strongest?', '123456', 'your first name', 'Kampala2026', 'Blue!Mango7Rain', 'D'),
(@session, 'A message says you won a prize and asks for your mobile-money PIN. What should you do?', 'Send the PIN quickly before the offer ends', 'Ignore or report it — providers never ask for your PIN', 'Forward it to friends', 'Reply asking for more details', 'B'),
(@session, 'What is the best way to check if information online is reliable?', 'See how many likes it has', 'Compare it with at least two trusted sources', 'Trust it if it has a picture', 'Believe it if a friend shared it', 'B'),
(@session, 'What does two-step verification do?', 'Makes your phone faster', 'Adds a second check, such as an SMS code, when you log in', 'Lets two people share one account', 'Deletes old passwords', 'B'),
(@session, 'Which habit helps you save mobile data?', 'Streaming every video in HD', 'Leaving many apps running', 'Downloading notes on Wi-Fi to read later', 'Turning off Wi-Fi at home', 'C');

-- AI Tools for Everyday Life: Using AI Responsibly
INSERT INTO activities (title, topic, description, session_date, duration_mins, facilitator_id, low_bandwidth, notes)
VALUES ('AI Tools for Everyday Life: Using AI Responsibly', 'AI Literacy', 'How AI chat tools work, what they are good at, their limits, and how to use them honestly.', '2026-10-08 09:00:00', 60, @facilitator, TRUE,
'What is AI?
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
2. Never paste private information (ID numbers, passwords, other people''s personal data) into an AI tool.
3. Be honest: say when and how you used AI. On YEP every Impact Project includes an AI-use declaration.
4. Use AI to help your thinking, not to replace it. You are responsible for the final work.');
SET @session = LAST_INSERT_ID();
INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, option_c, option_d, correct_option) VALUES
(@session, 'What does it mean when an AI tool "hallucinates"?', 'It stops working', 'It gives a confident answer that is false', 'It refuses to answer', 'It runs out of data', 'B'),
(@session, 'Which of these should you NEVER paste into an AI chat tool?', 'A question about photosynthesis', 'A request to summarise a public article', 'Your national ID number and passwords', 'A list of business ideas to improve', 'C'),
(@session, 'Why must YEP teams include an AI-use declaration with their project?', 'To be honest about how AI tools were used', 'Because AI is not allowed at all', 'So the mentor can give extra marks', 'To make the project longer', 'A'),
(@session, 'An AI tool gives you a statistic about youth unemployment in Uganda. What should you do?', 'Use it immediately', 'Check it against a reliable source such as UBOS', 'Round the number up', 'Ask the AI if it is sure and then use it', 'B'),
(@session, 'Which task is AI generally GOOD at?', 'Knowing today''s local prices without any data', 'Making final hiring decisions alone', 'Brainstorming ideas and drafting text', 'Guaranteeing facts are correct', 'C');

-- Spotting Fake News and Deepfakes
INSERT INTO activities (title, topic, description, session_date, duration_mins, facilitator_id, low_bandwidth, notes)
VALUES ('Spotting Fake News and Deepfakes', 'Media Literacy', 'How false information spreads on WhatsApp and social media, and simple checks before you share.', '2026-10-15 10:00:00', 75, @facilitator, TRUE,
'Why it matters
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

Golden rule: if you are not sure, do not share.');
SET @session = LAST_INSERT_ID();
INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, option_c, option_d, correct_option) VALUES
(@session, 'What is the difference between misinformation and disinformation?', 'There is no difference', 'Disinformation is false information created on purpose to mislead', 'Misinformation is always true', 'Disinformation is only found in newspapers', 'B'),
(@session, 'What does the "S" in the SIFT check stand for?', 'Share', 'Search', 'Stop', 'Save', 'C'),
(@session, 'A shocking video of a politician spreads on WhatsApp. Which is a sign it may be a deepfake?', 'It was shared by many people', 'Lips do not match the words and the face edges look blurry', 'It is in colour', 'It is shorter than one minute', 'B'),
(@session, 'How can you check whether a photo is old or from another country?', 'Zoom in on it', 'Do a reverse image search', 'Ask the person who sent it', 'Check how many people forwarded it', 'B'),
(@session, 'You are not sure whether a message is true. What is the best action?', 'Share it with a warning', 'Share it only in family groups', 'Do not share it until you have checked', 'Change a few words and share it', 'C');

-- Critical Thinking for the Digital Age
INSERT INTO activities (title, topic, description, session_date, duration_mins, facilitator_id, low_bandwidth, notes)
VALUES ('Critical Thinking for the Digital Age', 'Critical Thinking', 'Asking good questions, separating facts from opinions and avoiding common thinking traps.', '2026-10-22 09:00:00', 60, @facilitator, FALSE,
'What is critical thinking?
Critical thinking means carefully judging information and arguments before you accept them. It is one of the skills employers in East Africa say they need most.

Facts and opinions
• A fact can be checked and proved, for example "Uganda''s 2024 census counted about 45 million people."
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
• Correlation is not causation: two things happening together does not prove one caused the other.');
SET @session = LAST_INSERT_ID();
INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, option_c, option_d, correct_option) VALUES
(@session, 'Which statement is a FACT rather than an opinion?', 'Football is the most exciting sport', 'Lake Victoria borders Uganda, Kenya and Tanzania', 'Online learning is boring', 'Nairobi has the best food', 'B'),
(@session, 'Only reading news that agrees with what you already believe is called…', 'Confirmation bias', 'Critical thinking', 'Media literacy', 'Fact-checking', 'A'),
(@session, '"Everyone in my group says this cure works, so it must be true." This is an example of…', 'Strong evidence', 'The bandwagon trap', 'A scientific study', 'Correlation', 'B'),
(@session, 'Ice-cream sales and drowning both rise in hot weather. What can we conclude?', 'Ice cream causes drowning', 'Drowning causes ice-cream sales', 'They happen together, but that does not prove one causes the other', 'Hot weather is not important', 'C'),
(@session, 'Which question is MOST useful when judging a claim?', 'How many emojis does it have?', 'What is the evidence, and who benefits?', 'Is it written in English?', 'How long is the message?', 'B');

-- Working Across Cultures in East Africa
INSERT INTO activities (title, topic, description, session_date, duration_mins, facilitator_id, low_bandwidth, notes)
VALUES ('Working Across Cultures in East Africa', 'Intercultural Communication', 'Communicating and working well in teams with youth from different countries, languages and backgrounds.', '2026-10-29 09:00:00', 60, @facilitator, FALSE,
'Why it matters for YEP
Level Two teams mix youth from Uganda, Kenya, Tanzania, Rwanda, Burundi and other EAC countries. Different cultures bring better ideas — but only if the team communicates well.

Differences you may notice
• Language: English, Kiswahili, French and local languages. Speak clearly, avoid slang, and check that people understood.
• Directness: some people say "no" directly, others prefer polite, indirect answers.
• Time: some groups treat meeting times strictly, others more flexibly. Agree on team rules early.
• Respect: greetings, titles and how people address elders differ between communities.

Good habits in a cross-country team
1. Listen actively: let people finish, then summarise what you heard.
2. Ask, don''t assume: "How is this done in your country?"
3. Agree on how and when you will meet, and which tools to use (WhatsApp, email, YEP).
4. Share tasks fairly and give everyone a chance to speak.
5. Disagree with ideas, not with people.

Stereotypes
A stereotype is a fixed, simple idea about a whole group ("people from X are lazy"). Stereotypes are unfair and stop teams from seeing each person''s real strengths.');
SET @session = LAST_INSERT_ID();
INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, option_c, option_d, correct_option) VALUES
(@session, 'What is "active listening"?', 'Talking more than others', 'Letting people finish and then summarising what you heard', 'Listening to music while working', 'Only listening to the team leader', 'B'),
(@session, 'A teammate''s answers are often indirect. What is the best response?', 'Assume they are hiding something', 'Ignore their ideas', 'Ask politely and check understanding, since communication styles differ', 'Report them to the mentor', 'C'),
(@session, 'Which of these is a stereotype?', '"Grace is good at design."', '"Our team meets on Tuesdays."', '"All people from one country are lazy."', '"Kiswahili is spoken in Tanzania."', 'C'),
(@session, 'What should a new cross-country team agree on early?', 'Nothing — it is better to be flexible', 'Meeting times, tools and how tasks are shared', 'Who is the most important member', 'Which country is best', 'B'),
(@session, 'What does "disagree with ideas, not with people" mean?', 'Never disagree', 'Criticise the suggestion respectfully, not the person who made it', 'Only agree with the leader', 'Stop talking to people you disagree with', 'B');

-- Building Your Online Portfolio
INSERT INTO activities (title, topic, description, session_date, duration_mins, facilitator_id, low_bandwidth, notes)
VALUES ('Building Your Online Portfolio', 'Employability', 'Show employers what you can do: CVs, LinkedIn and simple portfolio websites. (Upcoming session.)', '2026-12-03 14:00:00', 60, @facilitator, TRUE,
'Why a portfolio?
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
Use a clear photo, check spelling, and remove anything you would not want an employer to see.');
SET @session = LAST_INSERT_ID();
INSERT INTO quiz_questions (activity_id, question_text, option_a, option_b, option_c, option_d, correct_option) VALUES
(@session, 'What is the main purpose of a portfolio?', 'To list your hobbies', 'To show real examples of what you can do', 'To replace your ID', 'To store passwords', 'B'),
(@session, 'Why include the verification code of your YEP certificate?', 'It looks nice', 'So employers can confirm the certificate is genuine', 'It is required by law', 'To get extra points', 'B'),
(@session, 'How many work examples are recommended?', 'None', 'Exactly one', 'About 3–5', 'At least 50', 'C'),
(@session, 'Which is a free place to publish a portfolio?', 'Google Sites', 'A paid TV advert', 'A bank account', 'Mobile money', 'A'),
(@session, 'Before sharing your portfolio you should…', 'Add as many selfies as possible', 'Check spelling and remove anything unprofessional', 'Include your passwords', 'Make it at least 100 pages', 'B');

-- -------------------------------------------------------
-- SAMPLE PARTNER OPPORTUNITIES (FR24)
-- -------------------------------------------------------
SET @admin = (SELECT user_id FROM users WHERE email = 'admin@yep.org');
INSERT INTO opportunities (title, organisation, opp_type, description, country, deadline, apply_link, posted_by) VALUES
('Junior Data Assistant Internship', 'Kampala Digital Hub', 'internship', 'A 3-month paid internship cleaning and visualising data for local NGOs. Basic spreadsheet skills required; YEP Level One certificate preferred.', 'Uganda', '2027-01-31', 'https://example.org/apply/data-intern', @admin),
('Climate Solutions Challenge 2027', 'Green Futures East Africa', 'challenge', 'Teams propose a low-cost digital idea that helps farmers adapt to climate change. The best 3 teams receive seed funding and mentoring.', NULL, '2027-02-28', 'https://example.org/climate-challenge', @admin),
('Social Media Officer (Remote)', 'Youth Voices Network', 'internship', 'Help run social media campaigns for youth programmes. Must understand online safety and how to spot misinformation.', 'Kenya', '2027-01-15', NULL, @admin);
