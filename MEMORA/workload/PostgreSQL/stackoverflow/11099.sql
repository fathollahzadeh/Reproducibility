
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentTotal,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRanking
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),

AggregatedMetrics AS (
    SELECT 
        PostTypeId,
        COUNT(PostId) AS TotalPosts,
        AVG(ViewCount) AS AverageViews,
        AVG(Score) AS AverageScore,
        AVG(AnswerCount) AS AverageAnswers,
        AVG(CommentTotal) AS AverageComments,
        AVG(FavoriteCount) AS AverageFavorites
    FROM 
        PostMetrics
    GROUP BY 
        PostTypeId
)

SELECT 
    pt.Name AS PostTypeName,
    am.TotalPosts,
    am.AverageViews,
    am.AverageScore,
    am.AverageAnswers,
    am.AverageComments,
    am.AverageFavorites
FROM 
    AggregatedMetrics am
JOIN 
    PostTypes pt ON am.PostTypeId = pt.Id
ORDER BY 
    am.TotalPosts DESC;
