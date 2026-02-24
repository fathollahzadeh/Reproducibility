WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' AND
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
user_stats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
top_users AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.TotalViews,
        ROW_NUMBER() OVER (ORDER BY us.TotalViews DESC) AS UserRank
    FROM 
        user_stats us
)
SELECT 
    up.DisplayName,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViews,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.TotalViews
FROM 
    ranked_posts rp
JOIN 
    top_users up ON rp.PostId = (SELECT 
                                       TopPostId 
                                   FROM (
                                       SELECT 
                                           p.Id AS TopPostId, 
                                           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank 
                                       FROM 
                                           Posts p 
                                       WHERE 
                                           p.OwnerUserId IS NOT NULL
                                   ) AS ranked 
                                   WHERE 
                                       ranked.PostRank = 1 AND ranked.TopPostId = rp.PostId)
WHERE 
    up.UserRank <= 10
ORDER BY 
    up.TotalViews DESC;