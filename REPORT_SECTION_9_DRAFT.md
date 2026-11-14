# Draft — replacement for Report Section 9 "Prototype Implementation"

> The current Section 9 in `YEP_Report (2).pdf` describes a console program with in-memory
> data and logins such as `admin@yep.ug / Admin2026`. The prototype is now a web application
> with a MySQL database. Paste and adapt the text below. Also update the Abstract ("console-based
> Java prototype" → "web-based Java prototype"), §1.4 Scope and §10.2 Limitations.

---

## 9. Prototype Implementation

We built a working web prototype of YEP in Java using Jakarta Servlets and JSP. It runs on
Apache Tomcat 10.1 and stores its data in a MySQL database (XAMPP). We chose plain servlets
instead of a framework such as Spring Boot because they are what we covered in class. They
also make the request → controller → DAO → database flow easy to see and explain. The
prototype follows the three-tier architecture in Section 5.1 and the layers required by NFR10.

### 9.1 Project Structure

| Layer | Package | Main classes |
|-------|---------|--------------|
| Model | `com.yep.model` | `User` (abstract), `Participant`, `Facilitator`, `Mentor`, `Admin`, `Notifiable`, `Activity`, `Assessment`, `Quiz`, `Question`, `Team`, `Project`, `Certificate` |
| Data access | `com.yep.dao` | `UserDAO`, `ActivityDAO`, `AssessmentDAO`, `TeamDAO`, `ProjectDAO`, `CertificateDAO`, `AuditLogDAO`, `ReportDAO` |
| Service | `com.yep.service` | `CertificateService`, `TeamService` |
| Controller | `com.yep.servlet` | `BaseServlet` (abstract), `AuthFilter`, `LoginServlet`, `RegisterServlet`, `SessionServlet`, `QuizServlet`, `ProjectServlet`, `AdminServlet`, `CertificateServlet` |
| View | `webapp/` | One JSP folder per role (participant, facilitator, mentor, admin) plus public login, registration and verification pages |

The database script `schema.sql` creates 13 tables that follow the ER design in Section 5.4.

### 9.2 How to Run

1. Start MySQL in XAMPP and import `schema.sql`.
2. Run the project from IntelliJ with Smart Tomcat, or build it with `mvn clean package` and
   deploy `yep-system.war` to Tomcat 10.1.
3. The database script already contains six sample Level One sessions, each with learning notes and
   a 5-question quiz. Open `/setup` once to also load demonstration participants: 8 youth from 5 EAC
   countries, with attendance and scores.
4. Sign in at `/login`. Demo accounts: `admin@yep.org / Admin@1234`,
   `alice@yep.org / Facil@1234` (facilitator), `brian@yep.org / Mentor@1234` (mentor),
   `amina@yep.org / Pass@1234` (participant).

### 9.3 Features Demonstrated

The prototype supports the whole YEP journey:
* registration with validation and consent (FR01–FR03)
* secure login with lock-out after three failed attempts, and an admin unlock (FR04)
* role-based dashboards (FR06)
* creating sessions with learning notes, and joining them by video, audio-only or downloadable
  notes, with participation points (FR07–FR09)
* an auto-graded multiple-choice quiz after each session (one attempt), with facilitator-recorded
  participation scores and grades (FR10–FR11)
* promotion to Level Two (FR12)
* automatic cross-country team formation (FR13)
* mentor assignment limited to three teams (FR14)
* Impact Project submission with a compulsory AI-use declaration, and mentor review (FR15–FR16)
* certificate issuing with eligibility checks and a unique code in the form `YEP-XXXX-XXXX` (FR19)
* public certificate verification without login (FR20)
* reports by country, gender, level, attendance mode, certificates and project status (FR21)
* staff account creation and account activation or deactivation (FR22)
* an audit log of important actions (NFR12)

### 9.4 Completing a Session

Following the session wireframe (Figure 6), a participant completes each Level One session in three
steps: (1) read the learning notes or download them as a small text file; (2) join by video,
audio-only or notes, which records attendance and awards 10 points; (3) take a 5-question
multiple-choice quiz. The quiz is marked automatically by `Quiz.grade()`, and the percentage is
saved in the `assessments` table, so it feeds directly into the participant's average and grade.
Each quiz can be taken only once, and its questions are locked after the first attempt, so all
participants are judged on the same questions. Once a participant has completed three sessions
with an average of 60% or more, the dashboard tells them they qualify. They then appear on the
administrator's promotion list, and the administrator makes the final decision (NFR11).

The prototype ships with six sample sessions based on the themes in the brief: digital literacy
and online safety, responsible AI, spotting fake news, critical thinking, intercultural
communication and online portfolios.

### 9.5 How OOP is Applied in the Code

* **Inheritance and polymorphism.** After login, `LoginServlet` redirects with
  `user.getDashboardMenu()`. Each subclass of `User` overrides this method, so one login flow
  serves all four roles. Every servlet also extends `BaseServlet`, which holds the shared
  login and role checks.
* **Encapsulation.** `Team.addMember(Participant)` refuses to add someone if the team already
  has five members, if the participant is not on Level Two, or if they are already in a team
  (pseudo-code 6.5). The member list can only be read, never changed directly.
* **Abstraction.** `User` and `BaseServlet` are abstract classes. The `Notifiable` interface
  hides how messages are delivered; in the prototype they are printed to the server log in
  place of SMS or email.
* **Exceptions.** Business-rule violations throw the custom `YEPException`, and its message is
  shown to the user. Technical errors are logged and the user sees a friendly error page.

The team formation algorithm improves on pseudo-code 6.4. It first calculates the number of
teams (`ceil(n / 5)`) so that every team has 3–5 members. It then places each participant in
the team with the fewest people from the same country, which spreads every country across the
teams. With the six eligible demo participants (two each from Kenya and Uganda, one each
from Rwanda and Tanzania), the algorithm forms two teams of three: Kenya–Uganda–Rwanda and
Kenya–Uganda–Tanzania.

### 9.6 Testing

We tested the prototype end to end with an automated script that drives the web pages
(134 checks, all passing). The main cases are below.

| Test | Input | Expected result | Actual |
|------|-------|-----------------|--------|
| T1 Valid registration | New participant aged 24, Kenya | Account created, message on login page | Pass |
| T2 Age limit | Date of birth in 1980 | "YEP is for youth aged 18 to 35 only", form keeps the data | Pass |
| T3 Duplicate email | `AMINA@yep.org` (different case) | "An account with this email already exists" | Pass |
| T4 Lock-out | 3 wrong passwords | Account locked; correct password refused until an admin unlocks it | Pass |
| T5 Attendance | Join the same session twice | 10 points on the first join; second join refused | Pass |
| T5b Quiz | New participant scores 5/5, 3/5 and 2/5 in three sessions | 66.7% average, told they qualify, appears on the promotion list | Pass |
| T5c One attempt | Submit the same quiz again, or skip a question | Refused with a clear message | Pass |
| T6 Invalid score | Score 120, or a participant who did not attend | Rejected with a clear message | Pass |
| T7 Promotion rule | Fatuma: 3 sessions, 55% average | Not promoted (needs 60%) | Pass |
| T8 Team mixing | 7 Level Two youth from 4 countries | 2 teams (4 + 3), every team has 3 countries | Pass |
| T9 Mentor limit | Mentor review of another mentor's team | Refused | Pass |
| T10 Certificate rules | Level One for someone with 1 session; duplicate certificate | Refused with the reason | Pass |
| T11 Verification | Real code (lower case) / fake code | GENUINE / NOT FOUND | Pass |
| T12 Security | `<script>` typed as a name; participant opening `/admin` | Shown as text, not run; access refused | Pass |
| T13 Password reset | Wrong code, then the right code | "2 tries left", then password changed and account unlocked | Pass |
| T14 Team chat | Post a message containing `<script>`; a teammate flags a message | Shown as text; message hidden and listed for the admin | Pass |
| T15 Portfolio privacy | Portfolio with *Show to employers* off / on; link `javascript:...` | Hidden / shown on Talent page; link refused | Pass |
| T16 Delete my data | Participant deletes the account with the correct password | Name, email and phone erased, account closed, statistics kept | Pass |

### 9.7 Limitations of the Prototype

SMS and email are simulated: notifications are printed to the server console, and the password
reset code is shown on screen in "demo mode". Partner organisations have no login of their own,
so the admin posts opportunities for them. The team chat updates when a message is sent, not
live. HTTPS, CSRF tokens and offline (PWA) mode would be needed before real use.
