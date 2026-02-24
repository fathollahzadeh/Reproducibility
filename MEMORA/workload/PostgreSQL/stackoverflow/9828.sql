
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges, 
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, 
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName, 
        p.Score, 
        p.ViewCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAYS')
        AND p.PostTypeId = 1
),
PostStatistics AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerDisplayName,
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        UserBadges pb ON rp.OwnerDisplayName = pb.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.BadgeCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 50;
