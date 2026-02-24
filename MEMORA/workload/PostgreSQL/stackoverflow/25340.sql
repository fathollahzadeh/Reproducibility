WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        tags.TagName,
        ROW_NUMBER() OVER (PARTITION BY tags.TagName ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE 
    JOIN 
        Tags tags ON tag = tags.TagName 
    WHERE 
        p.PostTypeId = 1 
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        TagName
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 3
),

TopCommenters AS (
    SELECT 
        c.UserDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        c.UserDisplayName
    ORDER BY 
        CommentCount DESC
    LIMIT 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.TagName,
    tc.UserDisplayName AS TopCommenter,
    tc.CommentCount
FROM 
    TopPosts tp
LEFT JOIN 
    TopCommenters tc ON tc.CommentCount = (SELECT MAX(CommentCount) FROM TopCommenters)
ORDER BY 
    tp.ViewCount DESC;