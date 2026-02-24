WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
UserPostCounts AS (
    SELECT OwnerUserId, COUNT(*) AS PostCount
    FROM Posts
    GROUP BY OwnerUserId
),
UserVoteCounts AS (
    SELECT UserId, COUNT(*) AS VoteCount
    FROM Votes
    GROUP BY UserId
),
UserCommentCounts AS (
    SELECT UserId, COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY UserId
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(ub.BadgeCount, 0) AS BadgeCount,
           COALESCE(up.PostCount, 0) AS PostCount,
           COALESCE(uv.VoteCount, 0) AS VoteCount,
           COALESCE(uc.CommentCount, 0) AS CommentCount
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN UserPostCounts up ON u.Id = up.OwnerUserId
    LEFT JOIN UserVoteCounts uv ON u.Id = uv.UserId
    LEFT JOIN UserCommentCounts uc ON u.Id = uc.UserId
)
SELECT UserId,
       DisplayName,
       BadgeCount,
       PostCount,
       VoteCount,
       CommentCount,
       (BadgeCount + PostCount + VoteCount + CommentCount) AS TotalActivity
FROM UserStats
ORDER BY TotalActivity DESC
LIMIT 100;