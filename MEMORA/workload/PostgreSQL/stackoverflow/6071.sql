WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalWikis,
        TotalViews,
        AvgScore,
        TotalComments,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalViews DESC) AS UserRank
    FROM 
        UserPosts
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalWikis,
    u.TotalViews,
    u.AvgScore,
    u.TotalComments,
    ROW_NUMBER() OVER (ORDER BY u.UserRank) AS RankedPosition
FROM 
    TopUsers u
WHERE 
    u.UserRank <= 10
ORDER BY 
    u.UserRank;
