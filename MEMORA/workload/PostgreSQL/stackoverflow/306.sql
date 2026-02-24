WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM UserReputation
    WHERE ReputationRank <= 10
),
PostSummary AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS TotalPosts,
           SUM(COALESCE(p.Score, 0)) AS TotalScore,
           COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
           COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
           SUM(p.ViewCount) AS TotalViews,
           MAX(p.CreationDate) AS LatestPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostDetails AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           ps.TotalPosts, 
           ps.TotalScore, 
           ps.Questions, 
           ps.Answers, 
           ps.TotalViews,
           ps.LatestPostDate,
           COALESCE(b.Count, 0) AS BadgeCount
    FROM TopUsers u
    LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS Count
        FROM Badges
        GROUP BY UserId
    ) b ON u.Id = b.UserId
)
SELECT u.DisplayName, 
       u.TotalPosts, 
       u.TotalScore, 
       u.Questions, 
       u.Answers,
       u.TotalViews,
       u.LatestPostDate,
       CASE 
           WHEN u.BadgeCount >= 5 THEN 'Active Contributor'
           ELSE 'New User'
       END AS UserStatus
FROM UserPostDetails u
WHERE u.TotalPosts > 0
ORDER BY u.TotalScore DESC;