WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        us.TotalVotes,
        us.UpVotes,
        us.DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    JOIN UserVoteStats us ON u.Id = us.UserId
    WHERE u.Reputation > 1000
    ORDER BY ReputationRank
    LIMIT 10
)
SELECT 
    ps.PostId,
    ps.Title,
    u.DisplayName AS PostOwner,
    ps.CommentCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes,
    tu.UserId AS TopUserId,
    tu.DisplayName AS TopUserDisplayName,
    tu.Reputation AS TopUserReputation,
    tu.TotalVotes AS TopUserTotalVotes
FROM PostStats ps
JOIN Users u ON ps.OwnerUserId = u.Id
JOIN TopUsers tu ON ps.UpVotes > 5 OR ps.DownVotes > 5
ORDER BY ps.CommentCount DESC, ps.UpVotes - ps.DownVotes DESC
LIMIT 20;