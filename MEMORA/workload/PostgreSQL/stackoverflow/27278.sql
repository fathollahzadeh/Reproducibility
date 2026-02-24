
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
),
FrequentTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 3
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.DisplayName,
        rp.PostType,
        rp.CommentCount,
        ft.Tag,
        ft.TagCount
    FROM 
        RankedPosts rp
    JOIN 
        FrequentTags ft ON rp.Title ILIKE '%' || ft.Tag || '%'
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.DisplayName,
    pd.PostType,
    pd.CommentCount,
    ARRAY_AGG(DISTINCT pd.Tag) AS Tags,
    SUM(pd.TagCount) AS TotalTagCount
FROM 
    PostDetails pd
GROUP BY 
    pd.PostId, pd.Title, pd.DisplayName, pd.PostType, pd.CommentCount
ORDER BY 
    TotalTagCount DESC, pd.CommentCount DESC
LIMIT 10;
