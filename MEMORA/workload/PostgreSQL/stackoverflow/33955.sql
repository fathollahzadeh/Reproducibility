WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
ClosedPostsWithDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        cp.FirstClosedDate,
        COALESCE(up.BadgeCount, 0) AS AuthorBadgeCount,
        COALESCE(up.GoldBadgeCount, 0) AS AuthorGoldCount,
        COALESCE(up.SilverBadgeCount, 0) AS AuthorSilverCount,
        COALESCE(up.BronzeBadgeCount, 0) AS AuthorBronzeCount
    FROM 
        Posts p
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
    LEFT JOIN 
        UserBadges up ON p.OwnerUserId = up.UserId
    WHERE 
        cp.FirstClosedDate IS NOT NULL
)
SELECT 
    cpd.PostId,
    cpd.Title,
    cpd.FirstClosedDate,
    r.Score,
    r.ViewCount,
    CASE 
        WHEN r.rn = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostRank,
    cpd.AuthorBadgeCount,
    CASE 
        WHEN cpd.AuthorGoldCount > 0 THEN 'Gold Badge Holder'
        WHEN cpd.AuthorSilverCount > 0 THEN 'Silver Badge Holder'
        WHEN cpd.AuthorBronzeCount > 0 THEN 'Bronze Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    ClosedPostsWithDetails cpd
JOIN 
    RankedPosts r ON cpd.PostId = r.Id
ORDER BY 
    cpd.FirstClosedDate DESC, 
    r.Score DESC;