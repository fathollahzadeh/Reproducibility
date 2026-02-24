WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostCommentSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT c.UserDisplayName, ', ') AS Commenters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.VoteCount,
    pcs.CommentCount,
    COALESCE(pcs.Commenters, 'No comments') AS Commenters,
    CASE 
        WHEN fp.Score > 100 THEN 'High Score'
        WHEN fp.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostCommentSummary pcs ON fp.PostId = pcs.PostId
WHERE 
    fp.ViewCount > 50
ORDER BY 
    fp.ViewCount DESC, fp.Score DESC;