WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostLinkCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
FinalMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        pc.LastCommentDate,
        COALESCE(plc.LinkCount, 0) AS LinkCount,
        ub.BadgeCount,
        ub.GoldBadgeCount,
        ub.SilverBadgeCount,
        ub.BronzeBadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        PostLinkCounts plc ON rp.PostId = plc.PostId
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fm.PostId,
    fm.Title,
    fm.Score,
    fm.ViewCount,
    fm.CommentCount,
    fm.LastCommentDate,
    fm.LinkCount,
    fm.BadgeCount,
    fm.GoldBadgeCount,
    fm.SilverBadgeCount,
    fm.BronzeBadgeCount
FROM 
    FinalMetrics fm
ORDER BY 
    fm.Score DESC, fm.ViewCount DESC
LIMIT 10;