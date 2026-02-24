
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),

UserRating AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN (u.UpVotes + 1) = 1 THEN NULL 
            ELSE (CAST(u.UpVotes AS FLOAT) / NULLIF(u.UpVotes + u.DownVotes, 0)) END AS UpvoteRatio
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        ur.UserId,
        ur.Reputation,
        ur.UpvoteRatio,
        COALESCE((
            SELECT 
                COUNT(DISTINCT bh.Id) 
            FROM 
                PostHistory bh 
            WHERE 
                bh.PostId = rp.PostId 
                AND bh.PostHistoryTypeId IN (10, 11) 
        ), 0) AS StatusChangeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        UserRating ur ON ur.UserId = u.Id
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.CommentCount,
    pm.Reputation,
    pm.UpvoteRatio,
    pm.StatusChangeCount,
    CASE 
        WHEN pm.UpvoteRatio IS NULL THEN 'New User'
        WHEN pm.UpvoteRatio >= 0.75 THEN 'Highly Recommended'
        WHEN pm.UpvoteRatio >= 0.5 THEN 'Recommended'
        WHEN pm.UpvoteRatio >= 0.25 THEN 'Needs Improvement'
        ELSE 'Low Interaction'
    END AS UserInteractionLevel
FROM 
    PostMetrics pm
WHERE 
    pm.StatusChangeCount > 0
ORDER BY 
    pm.Score DESC, 
    pm.CommentCount DESC
LIMIT 20;
