
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        UpVotes,
        DownVotes,
        CommentCount,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes DESC) AS Rank
    FROM UserActivity
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        AVG(COALESCE(p2.Score, 0)) AS AvgScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts p2 ON p.AcceptedAnswerId = p2.Id
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
)

SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.CommentCount,
    ps.Title,
    ps.CreationDate,
    ps.Score AS PostScore,
    ps.CommentCount AS TotalComments,
    ps.AvgScore AS AcceptedAnswerAvgScore
FROM TopUsers tu
JOIN PostStats ps ON tu.UserId = ps.PostId
WHERE tu.Rank <= 10
ORDER BY tu.Rank, ps.Score DESC;
