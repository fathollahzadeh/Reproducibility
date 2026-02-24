
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '>><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
), 
UserAchievements AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
    HAVING 
        COUNT(c.Id) > 10 AND p.ViewCount > 1000  
)
SELECT 
    t.TagName,
    tc.PostCount,
    ua.UserId,
    ua.DisplayName,
    ua.BadgeCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount
FROM 
    TagCounts tc
JOIN 
    Tags t ON t.TagName = tc.TagName
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
JOIN 
    UserAchievements ua ON p.OwnerUserId = ua.UserId
JOIN 
    PopularPosts pp ON p.Id = pp.PostId
WHERE 
    tc.PostCount > 5  
ORDER BY 
    tc.PostCount DESC, ua.BadgeCount DESC, pp.Score DESC;
