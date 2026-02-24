
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId, 
        ur.DisplayName, 
        ur.Reputation, 
        ur.PostCount,
        (ur.UpVotes - ur.DownVotes) AS NetVotes
    FROM UserReputation ur
    WHERE ur.PostCount > 0
    ORDER BY ur.Reputation DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.NetVotes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.CommentCount,
    pd.Score
FROM TopUsers tu
JOIN PostDetails pd ON tu.UserId = pd.PostId
ORDER BY tu.Reputation DESC, pd.Score DESC
