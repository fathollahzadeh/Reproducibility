WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounty,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges 
    WHERE 
        Class = 1 
    GROUP BY 
        UserId
),
FilteredUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.AnswerCount,
        us.QuestionCount,
        us.TotalBounty,
        us.UserRank,
        COALESCE(tb.BadgeCount, 0) AS GoldBadgeCount,
        COALESCE(tb.BadgeNames, 'None') AS GoldBadgeNames
    FROM 
        UserStatistics us
    LEFT JOIN 
        TopBadges tb ON us.UserId = tb.UserId
)
SELECT 
    fu.DisplayName,
    fu.Reputation,
    fu.PostCount,
    fu.AnswerCount,
    fu.QuestionCount,
    fu.TotalBounty,
    fu.UserRank,
    fu.GoldBadgeCount,
    fu.GoldBadgeNames
FROM 
    FilteredUsers fu
WHERE 
    fu.Reputation IS NOT NULL 
    AND fu.PostCount > 0
    AND fu.AnswerCount < fu.QuestionCount
ORDER BY 
    fu.UserRank, 
    fu.TotalBounty DESC;