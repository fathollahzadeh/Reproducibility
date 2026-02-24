WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews,
        COUNT(c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
)

SELECT
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    AcceptedAnswers,
    TotalScore,
    AverageViews,
    TotalComments
FROM UserPostStats
ORDER BY TotalScore DESC
LIMIT 100;