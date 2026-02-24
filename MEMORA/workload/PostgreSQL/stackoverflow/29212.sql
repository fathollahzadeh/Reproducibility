
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score >= 0 
),

TagAnalytics AS (
    SELECT 
        TRIM(both '>' FROM UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),

HighViewPost AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        ta.Tag,
        RANK() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank
    FROM 
        RankedPosts rp 
    JOIN 
        TagAnalytics ta ON ta.Tag IN (SELECT UNNEST(string_to_array(SUBSTRING(rp.Tags FROM 2 FOR LENGTH(rp.Tags) - 2), '><')))
    WHERE 
        rp.PostRank = 1 
)

SELECT 
    hvp.PostId,
    hvp.Title,
    hvp.CreationDate,
    hvp.ViewCount,
    hvp.Score,
    hvp.OwnerDisplayName,
    hvp.Tag
FROM 
    HighViewPost hvp
WHERE 
    hvp.ViewRank <= 10 
ORDER BY 
    hvp.ViewCount DESC;
