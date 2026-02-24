
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        t.TagName
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag) AS tag_table ON TRUE
    JOIN 
        Tags t ON t.TagName = tag_table.tag
    WHERE 
        t.Count > 10 
),
PostMetrics AS (
    SELECT 
        tp.OwnerDisplayName,
        COUNT(tp.PostId) AS TotalPosts,
        AVG(tp.ViewCount) AS AvgViews,
        SUM(tp.Score) AS TotalScore,
        STRING_AGG(DISTINCT tp.TagName, ', ') AS PopularTags
    FROM 
        TaggedPosts tp
    GROUP BY 
        tp.OwnerDisplayName
)
SELECT 
    pm.OwnerDisplayName,
    pm.TotalPosts,
    pm.AvgViews,
    pm.TotalScore,
    pm.PopularTags
FROM 
    PostMetrics pm
ORDER BY 
    pm.TotalScore DESC 
LIMIT 10;
