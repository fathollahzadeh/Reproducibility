WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeNames,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, 
        u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        TotalScore,
        BadgeNames,
        TotalComments,
        RANK() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalViews,
    t.TotalScore,
    t.BadgeNames,
    t.TotalComments
FROM 
    TopUsers t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;