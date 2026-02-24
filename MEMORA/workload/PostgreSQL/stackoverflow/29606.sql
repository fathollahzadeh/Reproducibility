
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT unnest(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName, p.Id AS PostId FROM Posts p) AS tag ON p.Id = tag.PostId
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.CommentCount,
        rp.TagsList,
        rp.RankByViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tp.TagsList,
    pt.TagName AS PopularTag
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         TagName, 
         COUNT(*) AS UsageCount 
     FROM 
         PopularTags 
     GROUP BY 
         TagName 
     HAVING 
         COUNT(*) >= 5) pt ON tp.TagsList LIKE '%' || pt.TagName || '%'
ORDER BY 
    tp.ViewCount DESC, tp.CommentCount DESC;
