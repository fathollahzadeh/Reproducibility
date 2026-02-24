WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId,
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
        ViewCount, 
        Score, 
        AnswerCount, 
        CommentCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostStatistics AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(tp.PostId) AS TotalPosts,
        AVG(tp.ViewCount) AS AvgViews,
        AVG(tp.Score) AS AvgScore,
        SUM(tp.AnswerCount) AS TotalAnswers,
        SUM(tp.CommentCount) AS TotalComments
    FROM 
        PostTypes pt
    LEFT JOIN 
        TopPosts tp ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = tp.PostId)
    GROUP BY 
        pt.Name
)
SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgViews,
    ps.AvgScore,
    ps.TotalAnswers,
    ps.TotalComments,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Posts) AS TotalPostsCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.AvgScore DESC;