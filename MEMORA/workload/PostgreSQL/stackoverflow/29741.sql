
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(unnest(string_to_array(Tags, '><'))) AS TagName
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1
),
TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags 
    GROUP BY 
        TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.Score,
    RP.OwnerName,
    RP.Rank,
    TP.TagName,
    TP.UsageCount
FROM 
    RankedPosts RP
JOIN 
    TagPopularity TP ON TP.TagName = ANY(string_to_array(RP.Tags, '><')) 
WHERE 
    RP.Rank <= 3 
ORDER BY 
    RP.OwnerName, RP.Score DESC, RP.ViewCount DESC;
