WITH UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Score
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.DisplayName,
        ur.ReputationRank,
        ps.PostId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.Score
    FROM UserReputation ur
    LEFT JOIN PostStats ps ON ur.Id = ps.OwnerUserId
    WHERE ur.ReputationRank <= 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
)
SELECT 
    tu.DisplayName,
    tu.ReputationRank,
    tu.PostId,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    tu.CommentCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.Score
FROM TopUsers tu
LEFT JOIN ClosedPosts cp ON tu.PostId = cp.PostId
ORDER BY tu.ReputationRank, tu.Score DESC;