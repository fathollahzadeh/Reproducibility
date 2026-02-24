WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        UserBadges
    WHERE 
        BadgeCount > 0
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ps.PostCount,
        ps.Questions,
        ps.Answers,
        ps.TotalViews,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        PostStatistics ps
    JOIN 
        Users u ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    upb.UserId,
    upb.DisplayName,
    upb.PostCount,
    upb.Questions,
    upb.Answers,
    upb.TotalViews,
    upb.BadgeCount,
    upb.BadgeNames,
    CASE 
        WHEN upb.BadgeCount >= 5 THEN 'Gold Contributor'
        WHEN upb.BadgeCount >= 3 THEN 'Silver Contributor'
        WHEN upb.BadgeCount >= 1 THEN 'Bronze Contributor'
        ELSE 'No Contribution' 
    END AS ContributionLevel
FROM 
    UserPostBadges upb
WHERE 
    upb.PostCount > 0
ORDER BY 
    upb.TotalViews DESC, upb.PostCount DESC;
