WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScorePerPost,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.QuestionsCount,
    u.AnswersCount,
    u.TotalScore,
    u.TotalViews,
    u.AvgScorePerPost,
    u.AvgViewsPerPost
FROM 
    UserPostStats u
ORDER BY 
    u.TotalScore DESC
LIMIT 10;