
WITH UserPostMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CommentCount,
        p.AnswerCount,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
        p.OwnerUserId  -- Include OwnerUserId for the JOIN
    FROM 
        Posts p
)

SELECT 
    upm.UserId,
    upm.DisplayName,
    upm.TotalPosts,
    upm.Questions,
    upm.Answers,
    upm.TotalViews,
    upm.TotalScore,
    upm.TotalAnswers,
    upm.TotalComments,
    upm.AverageScore,
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.Score,
    pm.CommentCount,
    pm.AnswerCount,
    pm.CreationDate,
    pm.TotalComments
FROM 
    UserPostMetrics upm
LEFT JOIN 
    PostMetrics pm ON upm.UserId = pm.OwnerUserId
ORDER BY 
    upm.TotalPosts DESC, upm.TotalScore DESC;
