
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankWithinUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score > 0
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        ARRAY_AGG(pt.TagName) AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        LATERAL UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS pt(TagName) ON pt.TagName IN (SELECT TagName FROM PopularTags)
    WHERE 
        rp.RankWithinUser = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score, rp.ViewCount
)
SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.OwnerDisplayName,
    tpd.Score,
    tpd.ViewCount,
    ARRAY_TO_STRING(tpd.Tags, ', ') AS RelatedTags
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.Score DESC, tpd.ViewCount DESC
LIMIT 20;
