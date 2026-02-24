
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(*) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        TopPosts p
    JOIN 
        PostTypes pt ON p.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
    GROUP BY 
        pt.Name
)
SELECT 
    ps.PostType,
    ps.PostCount,
    ps.AverageScore,
    ps.TotalViews,
    CONCAT(ROUND(ps.AverageScore, 2), ' / ', ROUND(NULLIF(ps.TotalViews, 0) / NULLIF(ps.PostCount, 0), 2)) AS ScoreViewRatio
FROM 
    PostStatistics ps
ORDER BY 
    ps.PostCount DESC, ps.AverageScore DESC;
