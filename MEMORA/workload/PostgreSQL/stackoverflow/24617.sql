
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS CloseEventRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(cp.CloseEventRank, 0) AS CloseRank,
        ur.Reputation,
        ur.BadgeCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    a.Title,
    a.Score,
    a.ViewCount,
    a.Reputation,
    a.BadgeCount,
    COALESCE(a.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN a.CloseRank > 0 THEN 'Closed'
        WHEN a.CloseRank = 0 THEN 'Active'
    END AS PostStatus,
    (SELECT MAX(SCORE) FROM AggregatedData WHERE Reputation > a.Reputation) AS HigherReputationScore
FROM 
    AggregatedData a
WHERE 
    a.ViewCount > 50
GROUP BY 
    a.Title,
    a.Score,
    a.ViewCount,
    a.Reputation,
    a.BadgeCount,
    a.CommentCount,
    a.CloseRank
ORDER BY 
    a.Score DESC, 
    a.CommentCount DESC
LIMIT 10 OFFSET 5;
