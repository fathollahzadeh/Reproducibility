
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 
),

TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(UNNEST(string_to_array(Tags, '><')))
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.OwnerDisplayName,
    r.Tags,
    ts.TagName,
    ts.PostCount
FROM 
    RankedPosts r
JOIN 
    TagStats ts ON ts.TagName = ANY(string_to_array(r.Tags, '><'))
WHERE 
    r.Rank = 1 
ORDER BY 
    r.Score DESC, r.ViewCount DESC
LIMIT 100;
