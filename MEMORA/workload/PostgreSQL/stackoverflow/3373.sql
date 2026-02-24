
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users u
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseActions,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteActions
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.ReputationCategory,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.RankByScore,
    pha.CloseActions,
    pha.DeleteActions,
    rp.CommentCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostHistoryAggregation pha ON rp.PostId = pha.PostId
WHERE 
    rp.RankByScore <= 5
    AND (rp.CommentCount IS NOT NULL AND rp.CommentCount > 0)
    AND (pha.CloseActions IS NULL OR pha.CloseActions < 2)
ORDER BY 
    up.Reputation DESC, rp.Score DESC;
