
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankInCategory,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, pt.Name, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.TagsArray,
    COALESCE(ph.Comment, 'No comments about post history') AS HistoryComment
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 
WHERE 
    rp.RankInCategory <= 5 
ORDER BY 
    rp.PostId, rp.RankInCategory;
