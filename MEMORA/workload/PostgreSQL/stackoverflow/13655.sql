WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount
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
        PostCount,
        TotalScore,
        AverageViewCount,
        CommentCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS RankByScore,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    AverageViewCount,
    CommentCount,
    RankByScore,
    RankByPosts
FROM 
    TopUsers
WHERE 
    RankByScore <= 10 OR RankByPosts <= 10
ORDER BY 
    RankByScore, RankByPosts;