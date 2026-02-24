WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users u
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
CombinedStats AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.Rank,
        ur.ReputationCategory,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AverageScore, 0) AS AverageScore,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount
    FROM UserReputation ur
    LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    LEFT JOIN BadgeCounts bc ON ur.UserId = bc.UserId
)
SELECT 
    cs.UserId,
    cs.Reputation,
    cs.Rank,
    cs.ReputationCategory,
    cs.PostCount,
    cs.TotalViews,
    cs.AverageScore,
    cs.BadgeCount,
    STRING_AGG(DISTINCT CASE WHEN p.Tags IS NOT NULL THEN p.Tags END, ', ') AS TagsUsed
FROM CombinedStats cs
LEFT JOIN Posts p ON cs.UserId = p.OwnerUserId
GROUP BY 
    cs.UserId, 
    cs.Reputation,
    cs.Rank,
    cs.ReputationCategory,
    cs.PostCount,
    cs.TotalViews,
    cs.AverageScore,
    cs.BadgeCount
HAVING 
    cs.BadgeCount > 1 
    AND COUNT(p.Id) > 5
ORDER BY cs.Rank ASC, cs.TotalViews DESC;
