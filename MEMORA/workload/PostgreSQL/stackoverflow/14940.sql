WITH UserPostCounts AS (
    SELECT OwnerUserId, COUNT(*) AS PostCount
    FROM Posts
    GROUP BY OwnerUserId
),
UserVoteCounts AS (
    SELECT UserId, COUNT(*) AS VoteCount
    FROM Votes
    GROUP BY UserId
),
UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
UserActivity AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(up.PostCount, 0) AS PostCount,
           COALESCE(uv.VoteCount, 0) AS VoteCount,
           COALESCE(ub.BadgeCount, 0) AS BadgeCount,
           u.Reputation,
           u.CreationDate,
           u.LastAccessDate
    FROM Users u
    LEFT JOIN UserPostCounts up ON u.Id = up.OwnerUserId
    LEFT JOIN UserVoteCounts uv ON u.Id = uv.UserId
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
)
SELECT UserId, 
       DisplayName, 
       PostCount, 
       VoteCount, 
       BadgeCount, 
       Reputation, 
       CreationDate, 
       LastAccessDate
FROM UserActivity
ORDER BY Reputation DESC, PostCount DESC, VoteCount DESC
LIMIT 100;