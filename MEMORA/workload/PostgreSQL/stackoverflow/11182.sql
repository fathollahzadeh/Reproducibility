WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTypeBreakdown AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        PostTypes pt
    LEFT JOIN 
        Posts p ON pt.Id = p.PostTypeId
    GROUP BY 
        pt.Name
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.AverageReputation,
    ptb.PostType,
    ptb.PostCount,
    ptb.TotalViewCount,
    ptb.AverageScore
FROM 
    UserPostStatistics ups
JOIN 
    PostTypeBreakdown ptb ON ups.TotalPosts > 0
ORDER BY 
    ups.TotalPosts DESC, ptb.PostCount DESC;