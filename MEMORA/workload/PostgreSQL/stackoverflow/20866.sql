
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditHistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    up.UserId,
    up.Reputation,
    ra.PostId,
    ra.Title,
    ra.Score,
    ra.ViewCount,
    ra.CreationDate,
    up.CommentCount,
    up.UpvoteCount,
    up.DownvoteCount,
    ph.LastEditDate,
    ph.EditHistoryCount,
    CASE 
        WHEN up.Reputation > 1000 THEN 'Expert'
        WHEN up.Reputation BETWEEN 500 AND 1000 THEN 'Enthusiast'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    UserActivity up
INNER JOIN 
    RankedPosts ra ON up.UserId = ra.PostId
LEFT JOIN 
    PostHistoryInfo ph ON ra.PostId = ph.PostId AND up.UserId = ph.UserId
WHERE 
    ra.Score > 10 
    AND (up.CommentCount IS NOT NULL OR up.UpvoteCount > 0)
    AND (ph.EditHistoryCount IS NULL OR ph.EditHistoryCount > 2)
ORDER BY 
    ra.Score DESC, 
    up.Reputation DESC
LIMIT 100
OFFSET 0;
