
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation > 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationTier
    FROM Users
    UNION ALL
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation > 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationTier
    FROM Users u
    INNER JOIN UserReputation ur ON u.Id = ur.Id
    WHERE ur.Reputation < u.Reputation
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM PostStatistics
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    u.DisplayName,
    ur.ReputationTier,
    pb.PostId,
    pb.Title,
    pb.Score,
    pb.ViewCount,
    pb.CommentCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM Users u
INNER JOIN UserReputation ur ON u.Id = ur.Id
INNER JOIN (
    SELECT PostId, Title, Score, ViewCount, CommentCount
    FROM PopularPosts
    WHERE Rank <= 10
) pb ON u.Id = (
    SELECT OwnerUserId FROM Posts p WHERE p.Id = pb.PostId
)
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE u.Reputation IS NOT NULL
ORDER BY ur.ReputationTier, pb.Score DESC;
