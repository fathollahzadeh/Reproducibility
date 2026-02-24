
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ub.UserId,
    u.DisplayName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    CASE
        WHEN rp.PostRank = 1 THEN 'Latest'
        WHEN rp.PostRank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS PostCategory
FROM 
    UserBadges ub
JOIN 
    Users u ON u.Id = ub.UserId
JOIN 
    (SELECT * FROM RankedPosts WHERE PostRank <= 10) rp ON u.Id = rp.OwnerUserId
WHERE 
    ub.TotalBadges IS NOT NULL 
ORDER BY 
    ub.TotalBadges DESC, 
    rp.ViewCount DESC
LIMIT 50;
