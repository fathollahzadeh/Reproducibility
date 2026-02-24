
WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        CASE 
            WHEN p.PostTypeId = 1 THEN p.Title
            ELSE NULL
        END AS QuestionTitle,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.ViewCount > 0
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(p.ViewCount) AS TotalViews,
        COALESCE(AVG(p.Score), 0) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.DisplayName,
    ua.BadgeCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.TotalViews,
    ua.AvgScore,
    rp.PostId,
    rp.QuestionTitle,
    rp.CreationDate,
    rp.Score, 
    rp.ViewCount,
    rp.CommentCount,
    CASE 
        WHEN rp.RecentPostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostCategory
FROM 
    UserAggregates ua
LEFT JOIN 
    RecursivePostCTE rp ON ua.UserId = rp.OwnerUserId
WHERE 
    (ua.BadgeCount > 5 OR ua.TotalViews > 1000)
    AND (rp.Score >= (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) OR rp.PostId IS NULL)
ORDER BY 
    ua.TotalViews DESC, 
    ua.AvgScore DESC;
