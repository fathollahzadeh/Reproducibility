WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.RevisionGUID,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(ph.Comment, '') AS LastEditComment,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges
    FROM Posts p
    LEFT JOIN RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
    LEFT JOIN UserBadges u ON p.OwnerUserId = u.UserId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.LastEditComment,
    ps.BadgeCount,
    ps.GoldBadges,
    ps.SilverBadges,
    ps.BronzeBadges,
    COALESCE(c.UserDisplayName, 'Community User') AS LastEditor
FROM PostStatistics ps
LEFT JOIN (
    SELECT 
        PostId, 
        UserDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS rn
    FROM Comments
) c ON ps.PostId = c.PostId AND c.rn = 1
ORDER BY ps.Score DESC, ps.ViewCount DESC
LIMIT 100;