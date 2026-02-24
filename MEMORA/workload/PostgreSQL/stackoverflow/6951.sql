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
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStatistics AS (
    SELECT 
        t.OwnerDisplayName,
        SUM(t.ViewCount) AS TotalViews,
        SUM(t.AnswerCount) AS TotalAnswers,
        AVG(t.Score) AS AverageScore
    FROM 
        TopPosts t
    GROUP BY 
        t.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalViews,
    ps.TotalAnswers,
    ps.AverageScore,
    COUNT(b.Id) AS BadgeCount
FROM 
    PostStatistics ps
LEFT JOIN 
    Badges b ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
GROUP BY 
    ps.OwnerDisplayName, ps.TotalViews, ps.TotalAnswers, ps.AverageScore
ORDER BY 
    ps.TotalViews DESC, ps.AverageScore DESC;