
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS PostCount,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS BodyContent,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.TotalBadges,
        ur.TotalReputation,
        RANK() OVER (ORDER BY ur.TotalReputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.TotalReputation IS NOT NULL
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.BodyContent,
    rp.Score,
    rp.ViewCount,
    COALESCE(tu.UserRank, 0) AS UserRank,
    tu.TotalBadges,
    CASE 
        WHEN rp.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Posts WHERE AcceptedAnswerId = rp.PostId)
        ELSE 0 
    END AS AcceptedAnswers,
    CASE 
        WHEN (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus,
    CASE 
        WHEN rp.Score >= 100 THEN 'High Score'
        WHEN rp.Score BETWEEN 50 AND 99 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.rn = 1
    AND (rp.Score > 10 OR rp.ViewCount > 100)
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
