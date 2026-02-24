
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
CloseReasonCount AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    u.Reputation,
    u.BadgeCount,
    u.AvgBounty,
    COALESCE(cr.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation'
        WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN rp.AnswerCount = 0 THEN 'No Answers'
        WHEN rp.AnswerCount >= 1 AND rp.Score > 0 THEN 'Good Answers'
        ELSE 'Poor Answers'
    END AS AnswerQuality
FROM 
    RankedPosts rp
JOIN 
    UserReputation u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    CloseReasonCount cr ON rp.PostId = cr.PostId
WHERE 
    rp.RN = 1
ORDER BY 
    rp.ViewCount DESC
LIMIT 50;
