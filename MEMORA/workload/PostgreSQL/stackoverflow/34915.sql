WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Votes
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END), 0) AS CloseCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(uv.Upvotes, 0) - COALESCE(uv.Downvotes, 0) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN UserVoteCounts uv ON u.Id = uv.UserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    ps.Title,
    ps.Score,
    ps.CommentCount,
    ps.CloseCount,
    ps.CreationDate,
    CASE 
        WHEN ps.PostRank = 1 THEN 'Latest Post'
        ELSE NULL 
    END AS PostStatus,
    CASE 
        WHEN us.Reputation >= 1000 THEN 'Gold'
        WHEN us.Reputation >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS Badge
FROM UserReputation us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
WHERE us.NetVotes >= 5
ORDER BY us.Reputation DESC, ps.CreationDate DESC
LIMIT 10;