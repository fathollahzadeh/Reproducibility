
WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        pd.TagName 
    FROM 
        Posts p
    JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(p.Tags, '><')) AS TagName
        ) pd ON true
    WHERE 
        p.Score > 50
)
SELECT 
    ud.DisplayName,
    ud.Reputation,
    rp.Title AS PopularPostTitle,
    rp.Score AS PopularPostScore,
    rp.ViewCount AS PopularPostViews,
    COALESCE(cte.PostId, 0) AS RecentPostId,
    COALESCE(cte.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(cte.CreationDate, DATE '1970-01-01') AS RecentPostDate
FROM 
    UserDetails ud
LEFT JOIN 
    RecursiveCTE cte ON ud.UserId = cte.OwnerUserId AND cte.rn = 1
LEFT JOIN 
    PopularPosts rp ON rp.Title LIKE '%' || ud.DisplayName || '%'
WHERE 
    ud.Reputation > 1000
ORDER BY 
    ud.Reputation DESC, 
    rp.Score DESC NULLS LAST
LIMIT 10;
