
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
), TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
), PopularTags AS (
    SELECT 
        LOWER(TRIM(SUBSTRING(t.TagName, 2, LENGTH(t.TagName) - 2))) AS CleanTag,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        CleanTag
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    trp.Title,
    trp.OwnerDisplayName,
    trp.Score,
    trp.ViewCount,
    p.CleanTag AS PopularTag
FROM 
    TopRankedPosts trp
JOIN 
    PopularTags p ON p.PostCount > 0
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
