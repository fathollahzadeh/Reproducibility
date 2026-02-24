WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.Id AS PostId, 
        rp.Title,
        rp.Score, 
        rp.ViewCount, 
        rp.OwnerUserId,
        ub.BadgeCount, 
        ub.GoldBadges, 
        ub.SilverBadges, 
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.UserRank = 1
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId, 
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title, 
    ps.Score, 
    ps.ViewCount,
    COALESCE(cpr.CloseReasons, 'No Close Reasons') AS CloseReasons,
    ps.BadgeCount,
    ps.GoldBadges,
    ps.SilverBadges,
    ps.BronzeBadges
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPostReasons cpr ON ps.PostId = cpr.PostId
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC
LIMIT 100;