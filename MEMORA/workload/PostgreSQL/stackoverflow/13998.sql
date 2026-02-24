
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(c.Id) AS TotalComments,
        COUNT(b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalViews,
        TotalScore,
        TotalComments,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM UserEngagement
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalViews,
    TotalScore,
    TotalComments,
    TotalBadges
FROM TopUsers
WHERE Rank <= 10;
