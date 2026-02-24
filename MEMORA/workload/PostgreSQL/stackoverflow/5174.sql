
WITH RankedUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           u.CreationDate,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation
    FROM RankedUsers
    WHERE Rank <= 10
),
PostStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
           COALESCE(NULLIF(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0), 0) AS AcceptedAnswers
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
),
UserPosts AS (
    SELECT u.UserId,
           u.DisplayName,
           COUNT(p.Id) AS PostCount,
           COALESCE(SUM(ps.CommentCount), 0) AS TotalComments,
           COALESCE(SUM(ps.UpVotes), 0) AS TotalUpVotes,
           COALESCE(SUM(ps.DownVotes), 0) AS TotalDownVotes,
           COALESCE(SUM(ps.AcceptedAnswers), 0) AS TotalAcceptedAnswers
    FROM TopUsers u
    LEFT JOIN Posts p ON u.UserId = p.OwnerUserId
    LEFT JOIN PostStats ps ON p.Id = ps.PostId
    GROUP BY u.UserId, u.DisplayName
)
SELECT u.DisplayName,
       u.PostCount,
       u.TotalComments,
       u.TotalUpVotes,
       u.TotalDownVotes,
       u.TotalAcceptedAnswers
FROM UserPosts u
ORDER BY u.PostCount DESC, u.TotalUpVotes DESC;
