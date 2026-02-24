WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId 
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
), PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        u.DisplayName,
        ur.ReputationLevel,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM RecentPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    JOIN UserReputation ur ON u.Id = ur.Id
    LEFT JOIN (
        SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
                       SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON rp.PostId = v.PostId
    WHERE rp.PostRank = 1
)

SELECT 
    pd.Title,
    pd.CreationDate,
    pd.DisplayName,
    pd.ReputationLevel,
    pd.UpVotes,
    pd.DownVotes,
    CASE 
        WHEN pd.UpVotes - pd.DownVotes > 0 THEN 'Positive'
        WHEN pd.UpVotes - pd.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteTrend
FROM PostDetails pd
JOIN Posts p ON pd.PostId = p.Id
WHERE p.ViewCount IS NOT NULL
ORDER BY pd.UpVotes DESC NULLS LAST
LIMIT 10;