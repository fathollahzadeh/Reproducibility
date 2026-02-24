
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        rp.OwnerUserId,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.AnswerCount) AS TotalAnswers,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation u ON rp.OwnerUserId = u.UserId
    LEFT JOIN 
        (SELECT UserId, COUNT(DISTINCT Id) AS BadgeCount 
         FROM Badges 
         GROUP BY UserId) ub ON rp.OwnerUserId = ub.UserId
    GROUP BY 
        rp.OwnerUserId, u.Reputation, ub.BadgeCount
)
SELECT 
    ps.OwnerUserId,
    ps.TotalScore,
    ps.TotalAnswers,
    ps.UserReputation,
    ps.UserBadgeCount,
    CASE 
        WHEN ps.UserReputation >= 1000 THEN 'Gold'
        WHEN ps.UserReputation >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS ReputationTier
FROM 
    PostStats ps
WHERE 
    ps.TotalAnswers > 5
ORDER BY 
    ps.TotalScore DESC
FETCH FIRST 10 ROWS ONLY;
