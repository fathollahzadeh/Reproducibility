
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
             unnest(string_to_array(Tags, '>')) AS TagName, 
             Id 
         FROM 
             Posts) AS t ON p.Id = t.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Tags,
        b.Name AS BadgeName,
        b.Class AS BadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (
            SELECT 
                Id 
            FROM 
                Users 
            WHERE 
                DisplayName = rp.OwnerDisplayName
            LIMIT 1
        )
),
AggregatedData AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.Body,
        pwb.CreationDate,
        pwb.ViewCount,
        pwb.Score,
        pwb.OwnerDisplayName,
        pwb.Tags,
        AVG(CASE WHEN pwb.BadgeClass = 1 THEN 1.0 ELSE 0 END) AS GoldBadges,
        AVG(CASE WHEN pwb.BadgeClass = 2 THEN 1.0 ELSE 0 END) AS SilverBadges,
        AVG(CASE WHEN pwb.BadgeClass = 3 THEN 1.0 ELSE 0 END) AS BronzeBadges
    FROM 
        PostWithBadges pwb
    GROUP BY 
        pwb.PostId, pwb.Title, pwb.Body, pwb.CreationDate, pwb.ViewCount, pwb.Score, pwb.OwnerDisplayName, pwb.Tags
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.Body,
    ad.CreationDate,
    ad.ViewCount,
    ad.Score,
    ad.OwnerDisplayName,
    ad.Tags,
    ad.GoldBadges,
    ad.SilverBadges,
    ad.BronzeBadges,
    RANK() OVER (ORDER BY ad.Score DESC) AS RankByScore,
    RANK() OVER (ORDER BY ad.ViewCount DESC) AS RankByViews
FROM 
    AggregatedData ad
WHERE 
    ad.ViewCount > 50  
ORDER BY 
    ad.Score DESC, ad.ViewCount DESC
LIMIT 10;
