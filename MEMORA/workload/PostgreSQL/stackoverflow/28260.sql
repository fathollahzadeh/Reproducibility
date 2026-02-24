WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
TagInfo AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        p.Id AS PostId
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION(t.TagName IN p.Tags) > 0 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.OwnerDisplayName,
    STRING_AGG(ti.TagName, ', ') AS AssociatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagInfo ti ON fp.PostId = ti.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CreationDate, fp.ViewCount, fp.Score, fp.OwnerDisplayName
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;