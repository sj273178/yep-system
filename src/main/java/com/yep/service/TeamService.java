package com.yep.service;

import com.yep.dao.AuditLogDAO;
import com.yep.dao.TeamDAO;
import com.yep.dao.UserDAO;
import com.yep.model.Participant;
import com.yep.model.Team;
import com.yep.util.ValidationUtil;
import com.yep.util.YEPException;

import java.sql.SQLException;
import java.util.*;

/**
 * TeamService — automatic cross-country team formation (FR13, report section 6.4).
 *
 * ALGORITHM (a refinement of the round-robin idea in the report):
 *   1. Work out how many teams are needed: ceil(n / 5). Sharing n people
 *      evenly between that many teams always gives teams of 3–5 when n >= 3.
 *   2. Group the waiting participants by country, biggest country first
 *      (the hardest to spread out).
 *   3. Place each participant in the team that has the FEWEST people from
 *      their country so far (ties: the smaller team). This spreads every
 *      country across the teams so each team is as mixed as possible.
 *   4. Team.addMember() checks the team rules for every participant.
 *
 *   Example: KE x2, UG x2, RW, TZ (6 people) → 2 teams:
 *            [KE, UG, RW] and [KE, UG, TZ]
 */
public class TeamService {

    private final UserDAO     userDAO  = new UserDAO();
    private final TeamDAO     teamDAO  = new TeamDAO();
    private final AuditLogDAO auditLog = new AuditLogDAO();

    /**
     * Forms and saves teams from all unassigned Level Two participants.
     *
     * @return the teams that were created
     * @throws YEPException if there are fewer than 3 participants waiting
     */
    public List<Team> formTeams(String focusArea, int adminId) throws YEPException, SQLException {
        if (!Arrays.asList(Team.FOCUS_AREAS).contains(focusArea)) {
            throw new YEPException("Please choose a valid focus area.");
        }

        List<Participant> waiting = userDAO.findLevel2WithoutTeam();
        if (waiting.size() < Team.MIN_SIZE) {
            throw new YEPException("At least " + Team.MIN_SIZE + " Level Two participants without a team are needed "
                + "(currently " + waiting.size() + ").");
        }

        List<Team> planned = planTeams(waiting, focusArea, teamDAO.countAll());

        // Save each team and link its members
        Map<Integer, Participant> byId = new HashMap<>();
        for (Participant p : waiting) byId.put(p.getUserId(), p);

        for (Team team : planned) {
            int teamId = teamDAO.create(team);
            team.setTeamId(teamId);
            for (int memberId : team.getMemberIds()) {
                userDAO.assignTeam(memberId, teamId);
                Participant p = byId.get(memberId);
                p.sendNotification("You have joined a YEP team",
                    "You are now a member of " + team.getName() + " (" + team.getFocusLabel() + ").");
            }
            auditLog.log(adminId, "form_team", team.getName() + " with " + team.getMemberCount() + " members");
        }
        return planned;
    }

    /**
     * Pure planning step (no database), so it is easy to test on its own.
     *
     * @param participants Level Two participants without a team (at least 3)
     * @param existingTeams number of teams already in the system, used for numbering
     */
    public static List<Team> planTeams(List<Participant> participants, String focusArea, int existingTeams)
            throws YEPException {

        int n = participants.size();

        // 1. Number of teams and the size of each one (sizes differ by at most 1)
        int teamCount = (int) Math.ceil(n / (double) Team.MAX_SIZE);
        int[] capacity = new int[teamCount];
        for (int i = 0; i < teamCount; i++) {
            capacity[i] = n / teamCount + (i < n % teamCount ? 1 : 0);
        }

        // 2. Group by country (TreeMap keeps the order predictable), biggest group first
        Map<String, List<Participant>> byCountry = new TreeMap<>();
        for (Participant p : participants) {
            byCountry.computeIfAbsent(p.getCountry(), c -> new ArrayList<>()).add(p);
        }
        List<List<Participant>> countryGroups = new ArrayList<>(byCountry.values());
        countryGroups.sort((a, b) -> b.size() - a.size());

        // 3. Place each person in the team with the fewest people from their country
        List<List<Participant>> groups = new ArrayList<>();
        for (int i = 0; i < teamCount; i++) groups.add(new ArrayList<>());

        for (List<Participant> sameCountry : countryGroups) {
            for (Participant p : sameCountry) {
                int best = -1;
                for (int t = 0; t < teamCount; t++) {
                    if (groups.get(t).size() >= capacity[t]) continue;      // team already full
                    if (best == -1
                        || countFrom(groups.get(t), p.getCountry()) < countFrom(groups.get(best), p.getCountry())
                        || (countFrom(groups.get(t), p.getCountry()) == countFrom(groups.get(best), p.getCountry())
                            && groups.get(t).size() < groups.get(best).size())) {
                        best = t;
                    }
                }
                groups.get(best).add(p);
            }
        }

        // 4. Build Team objects — addMember() enforces the team rules
        List<Team> teams = new ArrayList<>();
        for (int i = 0; i < groups.size(); i++) {
            List<Participant> group = groups.get(i);
            Team team = new Team(teamName(existingTeams + i + 1, group), focusArea);
            for (Participant p : group) team.addMember(p);
            teams.add(team);
        }
        return teams;
    }

    /** How many people in the group come from the given country. */
    private static int countFrom(List<Participant> group, String country) {
        int count = 0;
        for (Participant p : group) if (p.getCountry().equals(country)) count++;
        return count;
    }

    /** Builds a readable name such as "Team 3 (KE-TZ-UG)". */
    private static String teamName(int number, List<Participant> members) {
        Set<String> codes = new TreeSet<>();
        for (Participant p : members) codes.add(ValidationUtil.countryCode(p.getCountry()));
        return "Team " + number + " (" + String.join("-", codes) + ")";
    }
}
