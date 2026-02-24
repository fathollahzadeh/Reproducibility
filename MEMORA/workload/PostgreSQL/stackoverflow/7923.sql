WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(BadgeCount.BadgeTotal, 0) AS TotalBadges,
        COALESCE(PostStats.PostCount, 0) AS TotalPosts,
        COALESCE(VoteStats.VoteCount, 0) AS TotalVotes,
        COALESCE(ViewStats.ViewTotal, 0) AS TotalViews
    FROM 
        Users U
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeTotal
        FROM Badges
        GROUP BY UserId
    ) AS BadgeCount ON U.Id = BadgeCount.UserId
    LEFT JOIN (
        SELECT OwnerUserId, COUNT(*) AS PostCount
        FROM Posts
        GROUP BY OwnerUserId
    ) AS PostStats ON U.Id = PostStats.OwnerUserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY UserId
    ) AS VoteStats ON U.Id = VoteStats.UserId
    LEFT JOIN (
        SELECT U.Id AS UserId, SUM(P.ViewCount) AS ViewTotal
        FROM Users U
        JOIN Posts P ON U.Id = P.OwnerUserId
        GROUP BY U.Id
    ) AS ViewStats ON U.Id = ViewStats.UserId
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBadges,
        TotalPosts,
        TotalVotes,
        TotalViews,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalBadges,
    TotalPosts,
    TotalVotes,
    TotalViews,
    ReputationRank
FROM RankedUsers
WHERE TotalPosts > 0
ORDER BY TotalPosts DESC, Reputation DESC
LIMIT 10; 
