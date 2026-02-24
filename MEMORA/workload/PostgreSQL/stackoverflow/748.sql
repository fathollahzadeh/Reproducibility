
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(DISTINCT CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(DISTINCT CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadgeCount,
        COALESCE(ub.SilverBadges, 0) AS SilverBadgeCount,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadgeCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    a.DisplayName,
    a.GoldBadgeCount,
    a.SilverBadgeCount,
    a.BronzeBadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    a.TotalScore
FROM 
    ActiveUsers a
FULL OUTER JOIN 
    RankedPosts rp ON a.Id = rp.OwnerUserId AND rp.UserPostRank = 1
LEFT JOIN 
    PostsWithComments pc ON rp.PostId = pc.PostId
WHERE 
    a.TotalScore > 500 OR (rp.PostId IS NOT NULL AND rp.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months')
ORDER BY 
    a.TotalScore DESC, rp.Score DESC;
