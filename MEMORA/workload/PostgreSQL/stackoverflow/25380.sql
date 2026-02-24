
WITH TagStatistics AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS QuestionsCount,
        COUNT(DISTINCT a.Id) AS AnswersCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%') AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        QuestionsCount, 
        AnswersCount, 
        TotalViews, 
        TotalScore,
        CommentsCount,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStatistics
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tt.TagName,
    tt.QuestionsCount,
    tt.AnswersCount,
    tt.TotalViews,
    tt.TotalScore,
    tt.CommentsCount,
    ua.DisplayName AS TopUser,
    ua.PostsCount AS UserPostsCount,
    ua.TotalScore AS UserTotalScore,
    ua.CommentsCount AS UserCommentsCount
FROM 
    TopTags tt
JOIN 
    UserActivity ua ON tt.QuestionsCount > 0
WHERE 
    tt.ViewRank <= 5
ORDER BY 
    tt.ViewRank;
