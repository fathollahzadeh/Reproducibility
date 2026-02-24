WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.Tags,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.Tags, u.DisplayName
), 
TagMetrics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        SUM(pm.ViewCount) AS TotalViews,
        SUM(pm.Score) AS TotalScore,
        SUM(pm.AnswerCount) AS TotalAnswers,
        SUM(pm.CommentCount) AS TotalComments,
        SUM(pm.FavoriteCount) AS TotalFavorites
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostMetrics pm ON p.Id = pm.PostId
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    tm.TagId,
    tm.TagName,
    tm.TotalViews,
    tm.TotalScore,
    tm.TotalAnswers,
    tm.TotalComments,
    tm.TotalFavorites
FROM 
    TagMetrics tm
ORDER BY 
    tm.TotalViews DESC;