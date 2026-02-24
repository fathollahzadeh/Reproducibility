WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        CreationDate, 
        Score, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 
),
CommentsStats AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments,
        AVG(SCORE) AS AverageCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostStatistics AS (
    SELECT 
        tp.*,
        COALESCE(cs.TotalComments, 0) AS TotalComments,
        COALESCE(cs.AverageCommentScore, 0) AS AverageCommentScore
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentsStats cs ON tp.PostId = cs.PostId
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.ViewCount,
    ps.Score,
    ps.TotalComments,
    ps.AverageCommentScore,
    CASE 
        WHEN ps.Score >= 100 THEN 'High Scorer'
        WHEN ps.Score BETWEEN 50 AND 99 THEN 'Medium Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC;