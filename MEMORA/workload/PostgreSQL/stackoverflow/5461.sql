
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes  
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        uv.TotalVotes,
        uv.UpVotes,
        uv.DownVotes
    FROM Users u
    JOIN UserVoteCounts uv ON u.Id = uv.UserId
    ORDER BY uv.TotalVotes DESC, u.Reputation DESC
    LIMIT 10
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.EditCount,
        ps.UpVotes,
        ps.DownVotes,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotes DESC) AS Rank
    FROM PostStatistics ps
    WHERE ps.UpVotes > 0
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    pp.Title AS PopularPostTitle,
    pp.CommentCount,
    pp.EditCount,
    pp.UpVotes,
    pp.DownVotes
FROM TopUsers tu
JOIN PopularPosts pp ON pp.Rank <= 5
ORDER BY tu.Reputation DESC;
