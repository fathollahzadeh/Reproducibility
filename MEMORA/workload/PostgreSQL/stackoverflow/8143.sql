WITH UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(DISTINCT p.Id) AS PostCount, 
           COUNT(DISTINCT c.Id) AS CommentCount, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, 
           DisplayName, 
           PostCount, 
           CommentCount, 
           UpVoteCount, 
           DownVoteCount,
           RANK() OVER (ORDER BY PostCount DESC, UpVoteCount DESC) AS RankByPosts
    FROM UserActivity
)
SELECT tu.DisplayName, 
       tu.PostCount, 
       tu.CommentCount, 
       tu.UpVoteCount, 
       tu.DownVoteCount,
       b.Name AS BadgeName,
       b.Class AS BadgeClass
FROM TopUsers tu
LEFT JOIN Badges b ON tu.UserId = b.UserId
WHERE tu.RankByPosts <= 10 AND (b.Class = 1 OR b.Class = 2)
ORDER BY tu.RankByPosts, b.Class DESC;
