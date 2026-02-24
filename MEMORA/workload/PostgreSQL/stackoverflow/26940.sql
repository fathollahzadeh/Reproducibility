
WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1   
    GROUP BY 
        TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
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
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(pb.GoldBadges, 0) AS GoldBadges,
        COALESCE(pb.SilverBadges, 0) AS SilverBadges,
        COALESCE(pb.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        UserBadges pb ON p.OwnerUserId = pb.UserId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 DAY'
),
TopTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        ROW_NUMBER() OVER (ORDER BY tc.PostCount DESC) AS TagRank
    FROM 
        TagCounts tc
)
SELECT 
    ta.TagName,
    ta.PostCount,
    pa.Title,
    pa.CreationDate,
    pa.AnswerCount,
    pa.CommentCount,
    pa.ViewCount,
    pa.FavoriteCount,
    pa.GoldBadges,
    pa.SilverBadges,
    pa.BronzeBadges
FROM 
    TopTags ta
JOIN 
    PostActivity pa ON pa.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p
        WHERE 
            p.Tags LIKE '%' || ta.TagName || '%'
    )
WHERE 
    ta.TagRank <= 10 
ORDER BY 
    ta.PostCount DESC, pa.ViewCount DESC;
