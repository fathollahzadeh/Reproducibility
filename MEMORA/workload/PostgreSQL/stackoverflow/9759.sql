WITH UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, COUNT(p.Id) AS PostCount, SUM(b.Class) AS BadgeScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, PostCount, BadgeScore,
           RANK() OVER (ORDER BY Reputation DESC, BadgeScore DESC) AS UserRank
    FROM UserReputation
),
UserPosts AS (
    SELECT t.UserId, COUNT(p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM TopUsers t
    JOIN Posts p ON t.UserId = p.OwnerUserId
    GROUP BY t.UserId
)
SELECT t.DisplayName, t.Reputation, t.PostCount, t.BadgeScore, 
       up.TotalPosts, up.Questions, up.Answers
FROM TopUsers t
JOIN UserPosts up ON t.UserId = up.UserId
WHERE t.UserRank <= 10
ORDER BY t.UserRank;
