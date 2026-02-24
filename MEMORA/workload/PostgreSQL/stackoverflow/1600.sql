WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
CommentsWithVotes AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Comments c
    LEFT JOIN 
        Votes v ON c.PostId = v.PostId
    GROUP BY 
        c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        cp.CommentCount,
        cp.Upvotes,
        cp.Downvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentsWithVotes cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.Upvotes,
    fp.Downvotes,
    CASE 
        WHEN fp.Score >= 10 THEN 'High Score'
        WHEN fp.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    FilteredPosts fp
WHERE 
    (fp.CommentCount > 0 OR fp.Upvotes > 0)
ORDER BY 
    fp.Score DESC, 
    fp.CommentCount DESC;