WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagPostStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    u.TotalViews,
    u.TotalComments,
    t.TagName AS TopTag,
    t.TotalPosts AS TagPostCount,
    t.TotalQuestions AS TagQuestionCount,
    t.TotalAnswers AS TagAnswerCount,
    t.TotalViews AS TagViewCount
FROM 
    UserPostStats u
LEFT JOIN 
    TagPostStats t ON t.TagId = (
        SELECT 
            t2.Id 
        FROM 
            Tags t2 
        LEFT JOIN 
            Posts p2 ON p2.Tags LIKE '%' || t2.TagName || '%'
        WHERE 
            p2.OwnerUserId = u.UserId
        GROUP BY 
            t2.Id 
        ORDER BY 
            COUNT(p2.Id) DESC 
        LIMIT 1
    )
ORDER BY 
    u.TotalScore DESC
LIMIT 100;