WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
), 
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.PostRank,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        CASE 
            WHEN rp.Score > 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    fp.PostId,
    CONCAT('Post Title: ', fp.Title, ' | Score: ', fp.Score, ' | Created: ', fp.CreationDate, 
           ' | Comments: ', fp.CommentCount, ' | Upvotes: ', fp.Upvotes, ' | Downvotes: ', fp.Downvotes,
           ' | Owner: ', fp.OwnerDisplayName, ' | Score categorization: ', fp.ScoreCategory) AS PostSummary
FROM 
    FilteredPosts fp
WHERE 
    fp.CommentCount > 0
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM FilteredPosts) / 2;