
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(EXTRACT(EPOCH FROM p.CreationDate)) AS AvgPostAge
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TagPostStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViewCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    u.TotalViewCount,
    u.AvgPostAge,
    t.TagName,
    t.TotalPosts AS TagTotalPosts,
    t.TotalQuestions AS TagTotalQuestions,
    t.TotalAnswers AS TagTotalAnswers,
    t.TotalScore AS TagTotalScore,
    t.TotalViewCount AS TagTotalViewCount
FROM UserPostStats u
JOIN TagPostStats t ON u.TotalPosts > 0 
ORDER BY u.TotalScore DESC, t.TotalScore DESC
FETCH FIRST 100 ROWS ONLY;
