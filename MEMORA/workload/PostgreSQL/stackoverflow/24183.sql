WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(p.PostCount, 0) AS PostCount,
        COALESCE(p.TotalBounty, 0) AS TotalBounty,
        COALESCE(p.Questions, 0) AS Questions,
        COALESCE(p.Answers, 0) AS Answers
    FROM Users u
    LEFT JOIN UserBadgeStats b ON u.Id = b.UserId
    LEFT JOIN PostActivity p ON u.Id = p.OwnerUserId
),
UserRankedEngagement AS (
    SELECT 
        ue.*,
        RANK() OVER (ORDER BY (GoldBadges * 3 + SilverBadges * 2 + BronzeBadges) + PostCount * 0.5 DESC) AS EngagementRank
    FROM UserEngagement ue
)
SELECT 
    UserId,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    TotalBounty,
    Questions,
    Answers,
    EngagementRank,
    CASE 
        WHEN EngagementRank IS NULL THEN 'Unranked'
        WHEN EngagementRank <= 5 THEN 'Top Engaged'
        WHEN EngagementRank <= 10 THEN 'Moderately Engaged'
        ELSE 'Less Engaged'
    END AS EngagementCategory,
    CASE
        WHEN TotalBounty > 500 THEN 'High Bounty Contributor'
        WHEN TotalBounty BETWEEN 100 AND 500 THEN 'Moderate Bounty Contributor'
        ELSE 'Low Bounty Contributor'
    END AS BountyContributorCategory
FROM UserRankedEngagement 
WHERE EngagementRank IS NOT NULL 
ORDER BY EngagementRank;