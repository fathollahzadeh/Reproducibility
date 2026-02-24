
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(COUNT(DISTINCT c.Id) FILTER (WHERE c.UserId IS NOT NULL), 0) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
    GROUP BY 
        p.Id, p.Title, p.Score
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
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ub.UserId,
        ub.BadgeCount,
        LEAD(ps.ViewCount) OVER (PARTITION BY ub.UserId ORDER BY ps.ViewCount DESC) AS NextPostViewCount
    FROM 
        PostStats ps
    JOIN 
        Posts post ON ps.PostId = post.Id
    JOIN 
        Users u ON post.OwnerUserId = u.Id 
    JOIN 
        UserBadges ub ON ub.UserId = u.Id
    WHERE 
        ps.Score > 10 
)
SELECT 
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.BadgeCount,
    COALESCE((pp.NextPostViewCount - pp.ViewCount) / NULLIF(pp.ViewCount, 0), -1) AS ViewCountGrowthRate,
    CASE 
        WHEN pp.BadgeCount > 5 THEN 'High Achiever'
        WHEN pp.BadgeCount BETWEEN 3 AND 5 THEN 'Medium Achiever'
        ELSE 'Low Achiever'
    END AS AchievementLevel
FROM 
    PopularPosts pp
WHERE 
    pp.BadgeCount IS NOT NULL
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC
LIMIT 50;
