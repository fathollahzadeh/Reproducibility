WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
), TagPostCounts AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        ProcessedTags
    GROUP BY 
        TagName
), TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagPostCounts
    WHERE 
        PostCount > 1
), ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 ELSE 0 END) AS ActivePostsLast30Days
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(b.GoldCount, 0) AS GoldBadges,
    COALESCE(b.SilverCount, 0) AS SilverBadges,
    COALESCE(b.BronzeCount, 0) AS BronzeBadges,
    u.PostCount,
    u.ActivePostsLast30Days,
    tt.TagName,
    tt.PostCount AS TagPostCount
FROM 
    ActiveUsers u
LEFT JOIN 
    UserBadges b ON u.UserId = b.UserId
LEFT JOIN 
    TopTags tt ON tt.TagRank <= 5
ORDER BY 
    u.PostCount DESC, ActivePostsLast30Days DESC;