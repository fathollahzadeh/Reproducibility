WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalVotes,
        TotalComments,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalVotes DESC, TotalComments DESC) AS ActivityRank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalVotes,
    TotalComments,
    TotalViews,
    TotalScore,
    ActivityRank
FROM 
    RankedUsers
WHERE 
    ActivityRank <= 10
ORDER BY 
    ActivityRank;