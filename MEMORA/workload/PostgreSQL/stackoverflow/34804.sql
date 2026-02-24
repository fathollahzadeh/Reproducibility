WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 5
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RowNum
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRowNum
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
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
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    CASE 
        WHEN ub.BadgeCount > 0 THEN ub.BadgeCount 
        ELSE 0 
    END AS TotalBadges,
    ub.BadgeNames,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.CreationDate AS PopularPostDate,
    pp.Score AS PopularPostScore,
    ch.PostId AS ClosedPostId,
    ch.CreationDate AS ClosedPostDate,
    ch.UserDisplayName AS ClosedBy,
    ch.Comment AS CloseReason,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pp.PostId) AS CommentCount
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PopularPosts pp ON u.Id = pp.OwnerUserId AND pp.RowNum = 1
LEFT JOIN ClosedPostHistory ch ON pp.PostId = ch.PostId AND ch.HistoryRowNum = 1
WHERE u.Reputation > 2000
ORDER BY u.Reputation DESC, pp.Score DESC;