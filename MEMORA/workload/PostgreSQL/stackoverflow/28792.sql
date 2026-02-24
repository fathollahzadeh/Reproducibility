
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
),
TagDetails AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount,
        MIN(PostId) AS SampleTagId
    FROM (
        SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
            p.Id AS PostId
        FROM 
            Posts p
        WHERE 
            p.PostTypeId = 1  
    ) sub
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        (SELECT SUM(TagCount) FROM TagDetails) AS TotalTags,
        ROUND((TagCount * 1.0 / (SELECT SUM(TagCount) FROM TagDetails)) * 100, 2) AS Percentage
    FROM 
        TagDetails
    ORDER BY 
        TagCount DESC
    LIMIT 10
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
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        tt.TagName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        TopTags tt ON rp.Tags LIKE '%' || tt.TagName || '%'
    WHERE 
        rp.PostRank = 1  
)

SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    OwnerUserId,
    OwnerDisplayName,
    ViewCount,
    Score,
    TagName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    FinalOutput
ORDER BY 
    Score DESC, ViewCount DESC;
