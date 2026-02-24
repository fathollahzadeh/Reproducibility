WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 9) OVER (PARTITION BY p.OwnerUserId), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
        AND p.ViewCount > 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalPostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount,
        rp.TotalPosts,
        rp.TotalBounty,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        rc.CommentCount,
        rc.LastCommentDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        RecentComments rc ON rp.PostId = rc.PostId
    WHERE 
        rp.Rank <= 3  
)

SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.OwnerUserId,
    f.Score,
    f.ViewCount,
    f.TotalPosts,
    f.TotalBounty,
    COALESCE(f.BadgeCount, 0) AS BadgeCount,
    COALESCE(f.GoldBadges, 0) AS GoldBadges,
    COALESCE(f.SilverBadges, 0) AS SilverBadges,
    COALESCE(f.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(f.CommentCount, 0) AS CommentCount,
    f.LastCommentDate,
    CASE 
        WHEN f.Score > 100 THEN 'High Score'
        WHEN f.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN f.TotalBounty = 0 THEN 'No bounties offered'
        WHEN f.TotalBounty < 100 THEN 'Moderate bounties offered'
        ELSE 'High bounties offered'
    END AS BountyCategory
FROM 
    FinalPostMetrics f
ORDER BY 
    f.Score DESC, f.ViewCount DESC
LIMIT 100;