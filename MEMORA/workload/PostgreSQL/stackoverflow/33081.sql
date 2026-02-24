WITH RecursiveUserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
), UserVotes AS (
    SELECT UserId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
), PostStats AS (
    SELECT p.OwnerUserId, COUNT(*) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
), UserActivity AS (
    SELECT u.Id AS UserId, u.DisplayName,
           COALESCE(r.BadgeCount, 0) AS BadgeCount,
           COALESCE(v.UpVotes, 0) AS UpVotes,
           COALESCE(v.DownVotes, 0) AS DownVotes,
           COALESCE(s.TotalPosts, 0) AS TotalPosts,
           COALESCE(s.Questions, 0) AS Questions,
           COALESCE(s.Answers, 0) AS Answers,
           COALESCE(s.AvgScore, 0) AS AvgScore
    FROM Users u
    LEFT JOIN RecursiveUserBadges r ON u.Id = r.UserId
    LEFT JOIN UserVotes v ON u.Id = v.UserId
    LEFT JOIN PostStats s ON u.Id = s.OwnerUserId
), FilteredUsers AS (
    SELECT *
    FROM UserActivity
    WHERE BadgeCount > 5 AND UpVotes > DownVotes
)
SELECT u.UserId, u.DisplayName, u.BadgeCount, u.UpVotes, u.DownVotes,
       u.TotalPosts, u.Questions, u.Answers, u.AvgScore,
       RANK() OVER (ORDER BY u.BadgeCount DESC, u.UpVotes DESC) AS Rank
FROM FilteredUsers u
ORDER BY Rank
LIMIT 10;
