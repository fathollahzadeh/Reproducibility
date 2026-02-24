WITH Statistics AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(c.Id) AS TotalComments
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        p.OwnerUserId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        s.TotalPosts,
        s.TotalQuestions,
        s.TotalAnswers,
        s.AverageScore,
        s.TotalViews,
        s.TotalComments
    FROM
        Users u
    LEFT JOIN
        Statistics s ON u.Id = s.OwnerUserId
)
SELECT
    UserId,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AverageScore,
    TotalViews,
    TotalComments
FROM
    UserReputation
ORDER BY
    Reputation DESC
LIMIT 100;