WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS LastAccountCreate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

PostViewCounts AS (
    SELECT 
        p.OwnerUserId, 
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        MAX(p.CreationDate) AS LatestPostDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate BETWEEN cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND cast('2024-10-01 12:34:56' as timestamp)
    GROUP BY p.Id, p.OwnerUserId, v.VoteCount, v.DownVoteCount
)

SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.UserRank,
    ps.PostId,
    ps.CommentCount,
    pv.TotalViews,
    CASE 
        WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'More Upvotes'
        WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteStatus,
    CASE 
        WHEN ru.Reputation >= 1000 THEN 'High Reputation'
        WHEN ru.Reputation BETWEEN 500 AND 999 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationStatus
FROM RankedUsers ru
LEFT JOIN PostStatistics ps ON ru.UserId = ps.OwnerUserId
LEFT JOIN PostViewCounts pv ON ru.UserId = pv.OwnerUserId
WHERE ru.UserRank <= 50  
AND ps.CommentCount > 0   
ORDER BY ru.Reputation DESC, ps.CommentCount DESC;