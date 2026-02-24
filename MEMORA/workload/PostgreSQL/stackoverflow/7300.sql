WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND pt.Id IN (1, 2) 
),
TopPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE Rank <= 5
),
PostStatistics AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.OwnerDisplayName,
        pp.Score,
        pp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(cv.VoteCount, 0) AS VoteCount
    FROM 
        TopPosts pp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON pp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) cv ON pp.PostId = cv.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    CASE 
        WHEN ps.Score > 10 THEN 'High Score' 
        WHEN ps.Score BETWEEN 1 AND 10 THEN 'Moderate Score' 
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;