WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
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
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    pa.TotalBounty,
    pa.AverageCommentScore
FROM 
    Users u
JOIN 
    UserBadges up ON u.Id = up.UserId
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank <= 5
JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    up.BadgeCount > 0
ORDER BY 
    up.BadgeCount DESC, rp.Score DESC
LIMIT 10;