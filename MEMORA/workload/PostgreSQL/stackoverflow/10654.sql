WITH PostCounts AS (
    SELECT COUNT(*) AS TotalPosts, 
           COUNT(DISTINCT OwnerUserId) AS UniquePostOwners,
           COUNT(DISTINCT Tags) AS UniqueTags
    FROM Posts
),
UserCounts AS (
    SELECT COUNT(*) AS TotalUsers, 
           SUM(CASE WHEN Reputation > 0 THEN 1 ELSE 0 END) AS ActiveUsers
    FROM Users
),
CommentCounts AS (
    SELECT COUNT(*) AS TotalComments 
    FROM Comments
),
BadgeCounts AS (
    SELECT COUNT(*) AS TotalBadges
    FROM Badges
),
VoteCounts AS (
    SELECT COUNT(*) AS TotalVotes
    FROM Votes
)
SELECT 
    (SELECT TotalPosts FROM PostCounts) AS TotalPosts,
    (SELECT UniquePostOwners FROM PostCounts) AS UniquePostOwners,
    (SELECT UniqueTags FROM PostCounts) AS UniqueTags,
    (SELECT TotalUsers FROM UserCounts) AS TotalUsers,
    (SELECT ActiveUsers FROM UserCounts) AS ActiveUsers,
    (SELECT TotalComments FROM CommentCounts) AS TotalComments,
    (SELECT TotalBadges FROM BadgeCounts) AS TotalBadges,
    (SELECT TotalVotes FROM VoteCounts) AS TotalVotes;