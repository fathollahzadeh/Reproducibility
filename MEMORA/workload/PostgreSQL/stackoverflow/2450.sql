WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    u.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.TotalBounty,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    CASE
        WHEN rp.ScoreRank = 1 THEN 'Top Question'
        WHEN rp.ScoreRank <= 5 THEN 'Top 5 Questions'
        ELSE 'Other'
    END AS RankCategory
FROM 
    UserStatistics us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    us.Reputation > 1000
    AND (rp.Score IS NULL OR rp.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
ORDER BY 
    us.Reputation DESC, 
    us.QuestionCount DESC
LIMIT 10
OFFSET 0;