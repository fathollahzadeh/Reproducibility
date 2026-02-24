WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COALESCE(u.Reputation, 0) AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Score >= 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 5 AND 9 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.CreationDate,
    tp.Score AS PostScore,
    tp.ScoreCategory,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pc.AverageCommentScore, 0) AS AvgCommentScore,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = tp.Id AND v.VoteTypeId = 2) 
        THEN 'Has Upvotes' 
        ELSE 'No Upvotes' 
    END AS VoteStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.Id = pc.PostId
ORDER BY 
    tp.CreationDate DESC
LIMIT 10;