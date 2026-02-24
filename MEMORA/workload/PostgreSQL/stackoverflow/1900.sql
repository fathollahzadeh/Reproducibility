
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        uv.Upvotes,
        uv.Downvotes,
        pc.CommentCount,
        COALESCE(rp.OwnerUserId, -1) AS OwnerUserId,
        rp.PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVotes uv ON rp.PostId = uv.PostId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.Upvotes,
    pd.Downvotes,
    pd.CommentCount,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score'
        WHEN pd.Score >= 10 THEN 'High Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    u.DisplayName AS OwnerDisplayName
FROM 
    PostDetails pd
LEFT JOIN 
    Users u ON pd.OwnerUserId = u.Id
WHERE 
    pd.PostRank = 1 
    AND pd.ViewCount > 100 
    AND u.Reputation IS NOT NULL
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 50;
