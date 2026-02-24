
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.PostRank = 1 THEN 'Latest'
            WHEN rp.PostRank <= 5 THEN 'Recent'
            ELSE 'Older'
        END AS PostCategory
    FROM 
        RankedPosts rp
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    pc.CommentCount,
    pc.AllComments,
    rp.PostCategory,
    CASE 
        WHEN rp.Score >= 10 THEN 'High Score'
        WHEN rp.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views Yet'
        WHEN rp.ViewCount = 0 THEN 'Unseen'
        ELSE 'Seen'
    END AS ViewStatus
FROM 
    RecentPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.PostCategory = 'Recent'
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
