
WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    uv.TotalVotes,
    uv.UpVotes,
    uv.DownVotes,
    ps.PostId,
    ps.TotalComments,
    ps.TotalAnswers,
    ps.TotalUpVotes,
    ps.TotalDownVotes
FROM Users u
JOIN UserVotes uv ON u.Id = uv.UserId
JOIN PostStatistics ps ON ps.OwnerUserId = u.Id
ORDER BY u.Reputation DESC, uv.TotalVotes DESC;
