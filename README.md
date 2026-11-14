# YEP Management System — Java Web Prototype

Prototype for the **Youth Empowerment Project (YEP)**: a youth digital empowerment and virtual
exchange platform for young people aged 18–35 in East Africa.
Object-Oriented Programming Using Java, Year 2 Semester 1, CAT 2 group assignment.

**Technology:** Java 21 · Jakarta Servlets 6 + JSP · Apache Tomcat 10.1 · MySQL/MariaDB (XAMPP) · JDBC · BCrypt · Maven.
No frameworks are used. The app is plain servlets, JSP, HTML, CSS and a little JavaScript.

---

## 1. How to run

### Prerequisites
* JDK 21
* Apache Tomcat **10.1** (Tomcat 9 will not work because it uses `javax.*`, not `jakarta.*`)
* XAMPP (MySQL / MariaDB)
* Maven, or IntelliJ IDEA with the *Smart Tomcat* plugin

### Steps
1. **Start MySQL** in the XAMPP control panel.
2. **Create the database.** In phpMyAdmin open the *Import* tab and import `schema.sql`, or run
   `mysql -u root < schema.sql`.
   The script can be run again at any time to get a clean database.
   **Already have an older database?** Import `upgrade.sql` instead. It adds the new tables
   (`team_messages`, `opportunities`) and columns and keeps all your existing data.
3. **Check the DB settings** in `src/main/resources/database.properties`
   (by default `root` with no password on `localhost:3306`).
4. **Run the app**
   * *IntelliJ (Smart Tomcat):* press Run. The app is at **http://localhost:8080/yep/**
   * *Maven + Tomcat:* run `mvn clean package`, copy `target/yep-system.war` into Tomcat's
     `webapps/` folder, then open **http://localhost:8080/yep-system/**
   A fresh import already contains **6 sample Level One sessions**, each with learning notes and a
   5-question quiz, so a newly registered participant can start straight away.
5. **Load demo data (recommended).** Open `/setup` (for example `http://localhost:8080/yep/setup`)
   and click **Reset and load demo data**. This only works from the same computer or for a
   logged-in admin, because it deletes all existing data.

### Demo accounts

| Role        | Email             | Password      |
|-------------|-------------------|---------------|
| Admin       | admin@yep.org     | Admin@1234    |
| Facilitator | alice@yep.org     | Facil@1234    |
| Mentor      | brian@yep.org     | Mentor@1234   |
| Mentor      | esther@yep.org    | Mentor@1234 *(after /setup)* |
| Participants| amina@, david@, grace@, samuel@, fatuma@, peter@, halima@, joseph@ `yep.org` | Pass@1234 *(after /setup)* |

On the login page, clicking a role button fills in that role's demo account.

---

## 1b. Putting the app online (free)

Free combination: **TiDB Cloud Starter** (free MySQL-compatible database, no credit card) +
**Render** (free hosting for Docker apps). The free Render server sleeps after 15 minutes without
visitors, so the first visit after that takes about a minute. Open the site a few minutes before
presenting.

**1. Database (TiDB Cloud)**
1. Sign up at https://tidbcloud.com and create a free **Starter** cluster.
2. Click **Connect**, generate a password, and note the *host*, *port* (4000) and *user*
   (it looks like `xxxxxxxx.root`).
3. Import the tables from this folder:
   `/Applications/XAMPP/xamppfiles/bin/mysql -h HOST -P 4000 -u USER -p --ssl < schema.sql`

**2. Code on GitHub**
```bash
cd yep-system
git init && git add . && git commit -m "YEP System"
gh repo create yep-system --private --source=. --push   # or create the repo on github.com
```

**3. Hosting (Render)**
1. Sign up at https://render.com → **New → Web Service** → choose the GitHub repo.
2. Render finds the `Dockerfile` by itself. Choose the **Free** instance type.
3. Add these **Environment Variables**:

| Name | Value |
|------|-------|
| `DB_URL` | `jdbc:mysql://HOST:4000/yep_db?sslMode=VERIFY_IDENTITY&serverTimezone=UTC` |
| `DB_USERNAME` | your TiDB user, e.g. `xxxxxxxx.root` |
| `DB_PASSWORD` | your TiDB password |
| `PORT` | `8080` |

4. Click **Deploy**. After a few minutes the app is live at `https://<name>.onrender.com/`.
5. To load the demo data: sign in as `admin@yep.org`, then open `/setup`. Online, the setup page
   only works for a signed-in admin.

The database password lives only in Render's settings, not in the code. On your own computer
nothing changes: when the variables are not set, `database.properties` (XAMPP) is used.

---

## 2. How a participant completes sessions and gets promoted

Each Level One session is completed in **three steps** (wireframe "Session page", report p.26):

1. **Learn**: open the session and read the learning notes, or download them as a small `.txt`
   file (the low-data option). A recording link appears if the facilitator added one.
2. **Join**: choose *Video*, *Audio only* or *I read the notes*. This records attendance
   (FR08/FR09) and gives +10 points. Sessions can be joined from their start time onwards, and
   recordings and notes count the same as attending live (report §10.1).
3. **Quiz**: answer the 5 multiple-choice questions. The quiz is **marked automatically**, and
   the score is saved as an assessment of type `quiz` (FR10/FR11). There is **one attempt per
   session**, so the average stays fair. After submitting, the participant can review the
   correct answers.

When a participant has completed **3 sessions with an average of 60% or more**, the dashboard
says *"You qualify for Level Two"* and they appear on the admin's **Promote** page. The admin
confirms the promotion (FR12, NFR11: no automated decision on its own).

With 5 questions a quiz scores 0, 20, 40, 60, 80 or 100%. For example 5/5, 3/5 and 2/5 gives a
66.7% average, which qualifies.

**Facilitators** build quizzes under *Sessions → Quiz*: up to 10 questions, each with options A–D
and one correct answer. Creating a session opens the quiz editor straight away. Questions are
**locked once anyone has taken the quiz**, so everyone is marked on the same questions. For
sessions with an online quiz, the *Assessments* page records **participation** scores only.

**Sample sessions** (in `schema.sql` and loaded by `/setup` from `SampleContent.java`):
Digital Literacy & Online Safety · AI Tools – Using AI Responsibly · Spotting Fake News and
Deepfakes · Critical Thinking · Working Across Cultures · Building Your Online Portfolio
*(upcoming, opens 3 Dec 2026)*.

---

## 3. Suggested demonstration (≈10 minutes)

| # | Sign in as | Do this | Shows |
|---|-----------|---------|-------|
| 1 | — | Register a new participant with age 40, then with a valid age | FR01–FR03 validation; the form keeps what was typed |
| 2 | — | Enter a wrong password 3 times | FR04 lock-out |
| 3 | Admin | Users → **Unlock** the account | FR22 |
| 4 | Participant (peter@) | Sessions → *Spotting Fake News* → read notes → **Audio only** → take the quiz | FR08–FR11. Peter now has 3 sessions and qualifies |
| 5 | Facilitator | Sessions → *New Session* → add 2–3 quiz questions; Assessments → give a participation score | FR07, FR10 |
| 6 | Admin | Promote → **Promote All Eligible** | FR12 |
| 7 | Admin | Teams → **Form Teams Now** → assign Brian and Esther as mentors | FR13, FR14 |
| 8 | Participant in Team 1 | Project → save with an AI-use declaration → Submit | FR15, responsible AI |
| 9 | Mentor (brian@) | Projects → **Approve** | FR16 |
| 10 | Admin | Certificates → **Issue** Level One / Level Two | FR19 |
| 11 | — | Verify page → paste the code (e.g. `YEP-K7MP-Q3XR`) | FR20 |
| 12 | Admin | Reports, and Dashboard → *Recent Activity* | FR21, NFR12 audit log |
| 13 | Participant in Team 1 + mentor | My Team → **Team Discussion**: post messages, then flag one | FR17 |
| 14 | Admin | Dashboard → *Flagged Team Messages* → **Keep** or **Remove** | FR17 moderation |
| 15 | — | Login → **Forgot password?** → enter email → type the code shown in demo mode | FR05, also unlocks a locked account |
| 16 | Participant | Click your name (top right) → **My Profile**: fill in skills, tick *Show my portfolio* | FR23, privacy (view my data) |
| 17 | — (signed out) | Home page → **Talent** directory and **Opportunities** | FR23, FR24 |
| 18 | Admin | Opportunities → *Post a new opportunity* | FR24 |

---

## 4. Project structure

```
src/main/java/com/yep/
├── model/      User (abstract) ← Participant, Facilitator, Mentor, Admin
│               Notifiable (interface), Activity, Assessment, Team, Project,
│               Certificate, ParticipantProgress, Quiz, Question,
│               Message (team chat), Opportunity (partner postings)
├── dao/        One DAO per table group, JDBC + PreparedStatement only
│               UserDAO, ActivityDAO, AssessmentDAO, QuizDAO, TeamDAO,
│               ProjectDAO, CertificateDAO, AuditLogDAO, ReportDAO,
│               MessageDAO, OpportunityDAO
├── service/    Business rules that involve several tables
│               CertificateService (eligibility), TeamService (team formation),
│               SampleContent (the sample sessions, notes and quizzes)
├── servlet/    Controllers: BaseServlet (abstract parent of all servlets),
│               AuthFilter, Login/Register/Logout, Session, Question, Quiz, Team,
│               Project, Admin, Certificate(View), Setup,
│               ForgotPassword, Profile, Opportunity, Talent
└── util/       DatabaseConnection, PasswordUtil (BCrypt), ValidationUtil,
                DateUtil, SessionUtil, FlashMessage, YEPException
src/main/webapp/
├── index.jsp (public home page), login.jsp, register.jsp, forgot.jsp,
├── verify.jsp, certificate.jsp, profile.jsp, talent.jsp, opportunities.jsp, error.jsp
├── participant/  facilitator/  mentor/  admin/      (pages per role)
├── WEB-INF/nav.jspf                                 (shared menu + messages)
└── css/style.css, js/main.js
schema.sql                    (15 tables + staff accounts + 6 sample sessions with quizzes + 3 opportunities)
```

The layers follow NFR10 (*model, service, DAO, controller*). Servlets never contain SQL, and
DAOs never contain business rules.

---

## 5. Where the OOP principles appear

| Principle | Where |
|-----------|-------|
| **Encapsulation** | All fields are private. `Quiz.grade(answers)` does all the marking, and the quiz form never receives the correct answers. `Team.addMember()` checks that the team is not full, the participant is on Level Two and is not already in a team, and `getMemberIds()` returns a read-only list. `User` has no plain password getter. |
| **Inheritance** | `Participant`, `Facilitator`, `Mentor` and `Admin` extend the abstract `User`. Every servlet extends the abstract `BaseServlet`, so the login and role checks are written once. |
| **Polymorphism** | `getRole()` and `getDashboardMenu()` are overridden in each subclass. Login calls `user.getDashboardMenu()` without knowing the exact type. `UserDAO.insertUserRow(User u)` works for every subclass. |
| **Abstraction** | `User` and `BaseServlet` are abstract. The `Notifiable` interface hides *how* a notification is sent. |
| **Generics** | `BaseServlet.requireRole(req, resp, Facilitator.class)` returns a `Facilitator` with no cast needed. |
| **Exceptions** | The custom checked `YEPException` carries business-rule messages to the user. Technical errors are logged and shown as a friendly page. |
| **Composition** | A `Quiz` has a list of `Question`s, and a `ParticipantProgress` has a `Participant`. |
| **Collections** | `List`, `Map`, `TreeMap` and `Set` are used in team formation, reports and attendance look-ups. |

---

## 6. Business rules (from the report)

* **Registration (FR02):** age 18–35, EAC country, unique email (not case-sensitive), password of
  8+ characters with letters and numbers, consent required.
* **Lock-out (FR04):** 3 wrong passwords lock the account. An admin can unlock it.
* **Points (FR09):** each session attended earns 10 points.
* **Session completion:** join the session, then take its quiz (auto-graded, one attempt). Quiz
  questions are locked after the first attempt.
* **Grade (FR11):** Distinction ≥ 85, Merit ≥ 70, Pass ≥ 50, otherwise Not Yet Competent.
* **Level Two (FR12):** at least 3 sessions and an average of 60% or more. An admin confirms
  each promotion, so no automated decision is made alone (NFR11).
* **Teams (FR13):** teams of 3–5. Each person is placed in the team with the fewest people from
  their own country, so the teams are as mixed as possible.
* **Mentors (FR14):** at most 3 teams per mentor.
* **Project (FR15–16):** draft → submitted → approved, or revision requested. An AI-use
  declaration is required. Only the team's own mentor can review the project.
* **Certificates (FR19):** Level One needs 3+ sessions and a 50%+ average. Level Two needs an
  approved team project. Each type is issued once, with a random code `YEP-XXXX-XXXX`.
* **Verification (FR20):** public page with no login. It shows only the name, country, award
  and date.
* **Password reset (FR05):** a random 6-digit code is stored only as a BCrypt hash. It is valid for
  10 minutes and allows 3 tries. A reset also unlocks the account. The screen looks the same for
  unknown emails, so nobody can find out which emails are registered.
* **Team discussion (FR17):** team members, their mentor and admins can post. Anyone except the
  writer can flag a message, which hides it and lists it on the admin dashboard to keep or remove.
* **Portfolio (FR23):** participants add a bio, skills and a link. It appears on the public
  *Talent* page only if they tick *Show my portfolio*. Email, phone, age and gender are never shown.
* **Opportunities (FR24):** the admin posts internships and team challenges for partner
  organisations. Anyone can browse them, and they show as closed after the deadline.
* **Privacy:** *My Profile* shows all the data stored about the user. A participant can delete
  their data. The account is anonymised rather than removed, so programme statistics still add up.

## 7. Security and privacy measures

* BCrypt password hashing (cost 12).
* `PreparedStatement` for every query, against SQL injection.
* All user data is HTML-escaped before display, against XSS.
* `AuthFilter` and `requireRole()` provide role-based access control.
* The session ID is changed on login (prevents session fixation), and the session cookie is HttpOnly.
* A deactivated user is signed out on their next request.
* Login gives the same message for a wrong email and a wrong password.
* The audit log records logins, promotions, team formation, reviews and certificate issues.
* Phone numbers are never shown to other users, and reports use only aggregated numbers.

## 8. Known limitations (prototype)

* SMS and email notifications are simulated. They are printed to the Tomcat console as
  `[NOTIFICATION] ...`.
* The password reset code is shown on screen ("demo mode") because there is no real SMS/email gateway.
* Partner organisations do not have their own login. The admin posts opportunities for them.
* The team chat refreshes when a message is sent (no live updates).
* There are no CSRF tokens, HTTPS is not configured, and the PWA/offline mode is not implemented.
