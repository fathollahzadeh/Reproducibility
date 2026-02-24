WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostCounts AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(*) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.AnswerCount,
        COALESCE(pc.TotalPosts, 0) AS TotalPosts,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostCounts pc ON r.PostId = pc.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON r.PostId = ub.UserId
    WHERE 
        r.rn = 1
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.TotalPosts,
    (fp.BronzeBadges + 2 * fp.SilverBadges + 3 * fp.GoldBadges) AS TotalBadgePoints,
    CASE 
        WHEN fp.Score > 10 THEN 'High Score'
        WHEN fp.Score IS NULL THEN 'No Score'
        ELSE 'Moderate Score'
    END AS ScoreCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ViewCount DESC
LIMIT 50;