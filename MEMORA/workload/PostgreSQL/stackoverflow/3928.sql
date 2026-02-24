WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND p.ViewCount > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS CommentCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
ClosedPosts AS (
    SELECT 
        h.PostId,
        h.CreationDate,
        h.Comment AS CloseReason
    FROM 
        PostHistory h
    WHERE 
        h.PostHistoryTypeId = 10
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        u.DisplayName AS Owner,
        rp.Score,
        COALESCE(c.CloseReason, 'Not Closed') AS CloseStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        ClosedPosts c ON rp.PostId = c.PostId
    WHERE 
        rp.RankScore <= 5
)

SELECT 
    trp.Title,
    trp.CreationDate,
    trp.Owner,
    trp.Score,
    trp.CloseStatus,
    ur.Reputation,
    ur.PostCount,
    ur.CommentCount
FROM 
    TopRankedPosts trp
JOIN 
    UserReputation ur ON trp.Owner = ur.DisplayName
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC
LIMIT 10;
