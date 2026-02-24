
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    rp.Title,
    rp.ViewCount,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalScore
FROM 
    UserReputation ur
LEFT JOIN 
    PostStats ps ON ur.UserId = ps.OwnerUserId
JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    ur.Reputation DESC, rp.ViewCount DESC
LIMIT 10;
