
WITH UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation > 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
), PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        rp.OwnerUserId
    FROM RecentPosts rp
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON rp.PostId = c.PostId
), PostSummary AS (
    SELECT 
        wp.PostId,
        wp.Title,
        wp.CreationDate,
        wp.Score,
        wp.ViewCount,
        wp.CommentCount,
        ur.ReputationLevel,
        wp.OwnerUserId
    FROM PostWithComments wp
    JOIN UserReputation ur ON wp.OwnerUserId = ur.Id
    WHERE wp.Score >= 5
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    CONCAT(ur.DisplayName, ' - ', ps.ReputationLevel) AS UserInfo
FROM PostSummary ps
JOIN UserReputation ur ON ps.OwnerUserId = ur.Id
WHERE ps.CommentCount > 5
ORDER BY ps.Score DESC, ps.ViewCount ASC
LIMIT 10;
