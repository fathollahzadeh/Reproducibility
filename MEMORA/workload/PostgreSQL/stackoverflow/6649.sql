
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM Users u 
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
), 
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM UserPostStats
    WHERE TotalPosts > 0
    ORDER BY TotalScore DESC
    LIMIT 10
), 
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    JOIN ActiveUsers ub ON b.UserId = ub.UserId
    GROUP BY ub.UserId
)
SELECT 
    au.DisplayName,
    au.TotalPosts,
    au.Questions,
    au.Answers,
    au.TotalScore,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM ActiveUsers au
LEFT JOIN UserBadges ub ON au.UserId = ub.UserId
ORDER BY au.Rank;
