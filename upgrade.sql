-- ============================================================
-- YEP System — UPGRADE an existing database (keeps all data)
--
-- Use this if you imported an OLDER schema.sql before the team chat,
-- password reset, portfolio and opportunities features were added.
-- It only ADDS the new tables, columns and sample rows.
-- Safe to run more than once.
--
--   phpMyAdmin → select yep_db → Import → upgrade.sql
--   or:  mysql -u root < upgrade.sql
-- ============================================================
USE yep_db;
SET NAMES utf8mb4;

-- Forgotten-password reset (FR05)
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_code_hash VARCHAR(255) AFTER failed_logins;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_expires   DATETIME     AFTER reset_code_hash;

-- Skills portfolio (FR23)
ALTER TABLE participants ADD COLUMN IF NOT EXISTS bio              VARCHAR(500);
ALTER TABLE participants ADD COLUMN IF NOT EXISTS skills           VARCHAR(300);
ALTER TABLE participants ADD COLUMN IF NOT EXISTS portfolio_link   VARCHAR(300);
ALTER TABLE participants ADD COLUMN IF NOT EXISTS portfolio_public BOOLEAN NOT NULL DEFAULT FALSE;

-- Team discussion (FR17)
CREATE TABLE IF NOT EXISTS team_messages (
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

-- Partner opportunities (FR24)
CREATE TABLE IF NOT EXISTS opportunities (
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

-- Sample opportunities (only added if the table is empty)
SET @admin = (SELECT user_id FROM users WHERE role = 'ADMIN' ORDER BY user_id LIMIT 1);
INSERT INTO opportunities (title, organisation, opp_type, description, country, deadline, apply_link, posted_by)
SELECT * FROM (
    SELECT 'Junior Data Assistant Internship', 'Kampala Digital Hub', 'internship',
           'A 3-month paid internship cleaning and visualising data for local NGOs. Basic spreadsheet skills required; YEP Level One certificate preferred.',
           'Uganda', '2027-01-31', 'https://example.org/apply/data-intern', @admin
    UNION ALL
    SELECT 'Climate Solutions Challenge 2027', 'Green Futures East Africa', 'challenge',
           'Teams propose a low-cost digital idea that helps farmers adapt to climate change. The best 3 teams receive seed funding and mentoring.',
           NULL, '2027-02-28', 'https://example.org/climate-challenge', @admin
    UNION ALL
    SELECT 'Social Media Officer (Remote)', 'Youth Voices Network', 'internship',
           'Help run social media campaigns for youth programmes. Must understand online safety and how to spot misinformation.',
           'Kenya', '2027-01-15', NULL, @admin
) AS sample
WHERE @admin IS NOT NULL AND NOT EXISTS (SELECT 1 FROM opportunities);

-- Sample public portfolios for the demo participants (only if they exist and have no portfolio yet)
UPDATE participants p JOIN users u ON u.user_id = p.user_id
SET p.bio = 'Business student from Kampala who builds simple websites for small shops.',
    p.skills = 'Canva, Google Sites, Excel, Customer service',
    p.portfolio_link = 'https://sites.google.com/view/amina-portfolio', p.portfolio_public = TRUE
WHERE u.email = 'amina@yep.org' AND p.skills IS NULL;

UPDATE participants p JOIN users u ON u.user_id = p.user_id
SET p.bio = 'Computer science student interested in data and fighting misinformation online.',
    p.skills = 'Python basics, Data cleaning, Fact-checking, Public speaking', p.portfolio_public = TRUE
WHERE u.email = 'david@yep.org' AND p.skills IS NULL;

UPDATE participants p JOIN users u ON u.user_id = p.user_id
SET p.bio = 'Agriculture graduate using mobile tools to help farmers get better prices.',
    p.skills = 'Mobile money, Farmer training, Kinyarwanda/English translation', p.portfolio_public = TRUE
WHERE u.email = 'grace@yep.org' AND p.skills IS NULL;
