
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ARRAY_AGG(pr.Name) AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes pr ON CAST(ph.Comment AS INTEGER) = pr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId, ph.CreationDate
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ur.Reputation,
    ur.ReputationCategory,
    COALESCE(cp.CloseReasons, ARRAY[NULL]) AS CloseReasons,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.RecentPostRank
FROM PostStatistics ps
JOIN Users u ON ps.OwnerUserId = u.Id
JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
WHERE ps.Score > 0 AND ps.RecentPostRank <= 5
ORDER BY ps.CreationDate DESC;
