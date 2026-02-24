
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalViews, 
        TotalScore, 
        TotalPosts, 
        TotalComments, 
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserActivity
)
SELECT 
    t.DisplayName, 
    t.TotalViews, 
    t.TotalScore, 
    t.TotalPosts, 
    t.TotalComments,
    CASE 
        WHEN t.ViewRank <= 10 THEN 'Top Viewers'
        WHEN t.ScoreRank <= 10 THEN 'Top Scorers'
        ELSE 'Regular User'
    END AS UserType
FROM 
    TopUsers t
WHERE 
    t.TotalPosts > 5
ORDER BY 
    t.TotalViews DESC, 
    t.TotalScore DESC;
