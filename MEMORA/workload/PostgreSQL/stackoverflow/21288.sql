
WITH UserActivity AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 100 AND u.Location IS NOT NULL
    GROUP BY u.Id, u.DisplayName
),
ActiveQuestions AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ViewCount,
           p.Score,
           COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 AND p.ClosedDate IS NULL
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score
    HAVING COUNT(c.Id) > 5
),
UserStats AS (
    SELECT act.UserId,
           act.DisplayName,
           act.TotalPosts,
           act.Questions,
           act.Answers,
           act.UpVotes,
           act.DownVotes,
           COALESCE(q.TotalQuestions, 0) AS ActiveQuestionCount
    FROM UserActivity act
    LEFT JOIN (
        SELECT OwnerUserId, COUNT(*) AS TotalQuestions
        FROM Posts
        WHERE PostTypeId = 1 AND ClosedDate IS NULL
        GROUP BY OwnerUserId
    ) q ON act.UserId = q.OwnerUserId
)
SELECT usr.DisplayName,
       usr.TotalPosts,
       usr.Questions,
       usr.Answers,
       usr.UpVotes,
       usr.DownVotes,
       aq.Title,
       aq.ViewCount,
       aq.Score
FROM UserStats usr
LEFT JOIN ActiveQuestions aq ON aq.rn = 1
ORDER BY usr.TotalPosts DESC, aq.ViewCount DESC
LIMIT 10;
