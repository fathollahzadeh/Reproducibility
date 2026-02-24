
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostWithFlags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        CASE WHEN postFlags.AggrFlag > 0 THEN 'Flagged' ELSE 'Not Flagged' END AS FlagStatus,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS AggrFlag
        FROM Votes
        WHERE VoteTypeId IN (10, 12)  
        GROUP BY PostId
    ) AS postFlags ON p.Id = postFlags.PostId
    WHERE p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days') 
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.PostCount,
    pwf.PostId,
    pwf.Title,
    pwf.Score,
    pwf.FlagStatus
FROM UserStats us
FULL OUTER JOIN PostWithFlags pwf ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pwf.PostId LIMIT 1)
WHERE us.Reputation IS NOT NULL OR pwf.PostId IS NOT NULL
ORDER BY us.Reputation DESC, pwf.Score DESC
FETCH FIRST 50 ROWS ONLY;
