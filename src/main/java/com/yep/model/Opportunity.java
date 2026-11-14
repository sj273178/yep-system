package com.yep.model;

import java.time.LocalDate;

/**
 * Opportunity — an internship or challenge offered by a partner
 * organisation (FR24). The admin posts it on the partner's behalf and
 * participants and teams can browse it.
 */
public class Opportunity {

    public static final String TYPE_INTERNSHIP = "internship";
    public static final String TYPE_CHALLENGE  = "challenge";

    private int opportunityId;
    private String title;
    private String organisation;
    private String type;
    private String description;
    private String country;        // null = open to all EAC countries
    private LocalDate deadline;
    private String applyLink;

    public Opportunity(int opportunityId, String title, String organisation, String type,
                       String description, String country, LocalDate deadline, String applyLink) {
        this.opportunityId = opportunityId;
        this.title         = title;
        this.organisation  = organisation;
        this.type          = type;
        this.description   = description;
        this.country       = country;
        this.deadline      = deadline;
        this.applyLink     = applyLink;
    }

    /** An opportunity is open until the end of its deadline day. */
    public boolean isOpen() {
        return !LocalDate.now().isAfter(deadline);
    }

    public boolean isChallenge() { return TYPE_CHALLENGE.equals(type); }

    public String getTypeLabel() { return isChallenge() ? "Team Challenge" : "Internship"; }

    public String getCountryLabel() { return country == null ? "All EAC countries" : country; }

    public int getOpportunityId()   { return opportunityId; }
    public String getTitle()        { return title; }
    public String getOrganisation() { return organisation; }
    public String getType()         { return type; }
    public String getDescription()  { return description; }
    public String getCountry()      { return country; }
    public LocalDate getDeadline()  { return deadline; }
    public String getApplyLink()    { return applyLink; }
}
