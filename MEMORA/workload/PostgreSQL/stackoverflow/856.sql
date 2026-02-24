
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2) THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (3) THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        AVG(p.Score) OVER(PARTITION BY p.PostTypeId) AS AvgScore,
        ROW_NUMBER() OVER(ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.UpVotes,
        us.DownVotes,
        us.PostCount,
        ROW_NUMBER() OVER(ORDER BY (us.UpVotes - us.DownVotes + us.PostCount) DESC) AS Rank
    FROM UserScores us
)
SELECT 
    tu.DisplayName,
    tu.UpVotes,
    tu.DownVotes,
    ps.Title AS PopularPost,
    ps.CommentCount,
    ps.AvgScore
FROM TopUsers tu
LEFT JOIN PostStatistics ps ON tu.UserId = (
    SELECT p.OwnerUserId
    FROM Posts p
    WHERE p.Id = (
        SELECT PostId
        FROM PostStatistics
        WHERE CommentRank = 1
        LIMIT 1
    )
)
WHERE tu.Rank <= 10
ORDER BY tu.Rank;
