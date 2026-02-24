WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(p.FavoriteCount, 0)) AS TotalFavorites
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(DISTINCT pt.PostId) AS PostCount,
        SUM(COALESCE(up.TotalViews, 0)) AS TotalViewsPerTag,
        SUM(COALESCE(up.TotalAnswers, 0)) AS TotalAnswersPerTag,
        SUM(COALESCE(up.TotalComments, 0)) AS TotalCommentsPerTag,
        SUM(COALESCE(up.TotalFavorites, 0)) AS TotalFavoritesPerTag
    FROM 
        PostTags pt
    LEFT JOIN 
        UserPostStats up ON pt.PostId = up.UserId
    GROUP BY 
        Tag
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalViewsPerTag,
    tp.TotalAnswersPerTag,
    tp.TotalCommentsPerTag,
    tp.TotalFavoritesPerTag,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalViewsPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageViewsPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalAnswersPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageAnswersPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalCommentsPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageCommentsPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalFavoritesPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageFavoritesPerPost
FROM 
    TagPopularity tp
ORDER BY 
    tp.TotalViewsPerTag DESC, tp.Tag;