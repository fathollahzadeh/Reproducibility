WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Tags,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount,
        AVG(LENGTH(c.Text)) AS AvgCommentLength
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    up.DisplayName AS UserName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    COALESCE(cs.AvgCommentLength, 0) AS AverageCommentLength,
    CASE 
        WHEN rp.Score >= 100 THEN 'High Score'
        WHEN rp.Score BETWEEN 50 AND 99 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    CommentStats cs ON rp.PostId = cs.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate
FETCH FIRST 10 ROWS ONLY;
