
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.Score, 0) AS CommentScore,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, SUM(Score) AS Score 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS Gold,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS Silver,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS Bronze
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    u.DisplayName,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.CommentScore,
    COALESCE(b.Gold, 0) AS GoldBadges,
    COALESCE(b.Silver, 0) AS SilverBadges,
    COALESCE(b.Bronze, 0) AS BronzeBadges,
    t.TagName,
    t.TagCount
FROM 
    Users u
JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
JOIN 
    PopularTags t ON t.TagName = ANY(string_to_array(r.Tags, '><'))
WHERE 
    r.PostRank <= 3
ORDER BY 
    r.Score DESC, b.Gold DESC, b.Silver DESC
LIMIT 50;
