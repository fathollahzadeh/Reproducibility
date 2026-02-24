WITH UserPostCounts AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts
    FROM Posts
    GROUP BY OwnerUserId
),
UserVoteCounts AS (
    SELECT UserId, COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
)
SELECT 
    Users.DisplayName,
    Users.Reputation,
    COALESCE(UserPostCounts.TotalPosts, 0) AS TotalPosts,
    COALESCE(UserVoteCounts.TotalVotes, 0) AS TotalVotes,
    COALESCE(UserBadgeCounts.TotalBadges, 0) AS TotalBadges
FROM Users
LEFT JOIN UserPostCounts ON Users.Id = UserPostCounts.OwnerUserId
LEFT JOIN UserVoteCounts ON Users.Id = UserVoteCounts.UserId
LEFT JOIN UserBadgeCounts ON Users.Id = UserBadgeCounts.UserId
ORDER BY Users.Reputation DESC;
