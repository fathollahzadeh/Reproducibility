WITH UserBadgeRanks AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName, 
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE 
            WHEN Badges.Class = 1 THEN 3 
            WHEN Badges.Class = 2 THEN 2 
            WHEN Badges.Class = 3 THEN 1 
            ELSE 0 
        END) AS TotalBadgeValue
    FROM Users
    LEFT JOIN Badges ON Users.Id = Badges.UserId
    GROUP BY Users.Id, Users.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        RANK() OVER (ORDER BY TotalBadgeValue DESC) AS BadgeRank
    FROM UserBadgeRanks
    WHERE BadgeCount > 0
),
UserPostStatistics AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName, 
        COUNT(Posts.Id) AS PostCount, 
        AVG(Posts.Score) AS AvgPostScore
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id, Users.DisplayName
),
TopUsersWithPostStats AS (
    SELECT 
        t.UserId, 
        t.DisplayName, 
        t.BadgeRank, 
        ups.PostCount, 
        ups.AvgPostScore
    FROM TopUsers t
    JOIN UserPostStatistics ups ON t.UserId = ups.UserId
),
BenchmarkResults AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.BadgeRank,
        t.PostCount,
        t.AvgPostScore,
        (t.AvgPostScore * t.PostCount) AS PerformanceScore
    FROM TopUsersWithPostStats t
    WHERE t.BadgeRank <= 10  
)
SELECT 
    DisplayName, 
    BadgeRank, 
    PostCount, 
    AvgPostScore, 
    PerformanceScore
FROM BenchmarkResults
ORDER BY PerformanceScore DESC, BadgeRank ASC;