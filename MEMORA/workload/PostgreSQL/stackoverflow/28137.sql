
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
PostTagCounts AS (
    SELECT 
        unnest(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))
)
SELECT 
    ft.Title,
    ft.OwnerDisplayName,
    ft.Score,
    pt.TagName,
    pt.PostCount,
    ft.CreationDate
FROM 
    FilteredPosts ft
JOIN 
    PostTagCounts pt ON pt.TagName = ANY(string_to_array(SUBSTRING(ft.Tags FROM 2 FOR LENGTH(ft.Tags) - 2), '><'))
ORDER BY 
    pt.PostCount DESC, 
    ft.Score DESC
LIMIT 10;
