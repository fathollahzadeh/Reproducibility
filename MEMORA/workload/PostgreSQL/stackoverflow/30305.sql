WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),

UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),

PostsMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        ph.Level,
        u.DisplayName AS OwnerDisplayName,
        ub.BadgeCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM Posts p
    LEFT JOIN PostHierarchy ph ON p.Id = ph.Id
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UsersWithBadges ub ON u.Id = ub.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
)

SELECT 
    pm.Id,
    pm.Title,
    pm.ViewCount,
    pm.Score,
    pm.Level,
    pm.OwnerDisplayName,
    pm.BadgeCount,
    pm.UpVotes,
    pm.DownVotes,
    COALESCE(CAST(STRING_AGG(DISTINCT pst.Name, ', ') AS VARCHAR), 'No History') AS PostTypes
FROM PostsMetrics pm
LEFT JOIN PostHistory ph ON pm.Id = ph.PostId
LEFT JOIN PostHistoryTypes pst ON ph.PostHistoryTypeId = pst.Id
WHERE pm.ViewCount > 1000 AND pm.Score > 5
GROUP BY pm.Id, pm.Title, pm.ViewCount, pm.Score, pm.Level, pm.OwnerDisplayName, pm.BadgeCount, pm.UpVotes, pm.DownVotes
ORDER BY pm.Score DESC, pm.ViewCount DESC
LIMIT 50;
