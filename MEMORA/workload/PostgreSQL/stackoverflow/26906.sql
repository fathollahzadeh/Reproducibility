
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName,
        ts.TagName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag) AS tags ON TRUE
    LEFT JOIN 
        Tags ts ON ts.TagName = tags.tag
    WHERE 
        pt.Name = 'Question' 
        AND p.CreationDate >= DATE '2022-01-01'
),
TopTagCounts AS (
    SELECT 
        TagName,
        COUNT(PostId) AS PostCount
    FROM 
        TaggedPosts
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC 
    LIMIT 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.OwnerDisplayName,
        tt.PostCount,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        TaggedPosts tp
    JOIN 
        TopTagCounts tt ON tp.TagName = tt.TagName 
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId 
    LEFT JOIN 
        PostHistory ph ON tp.PostId = ph.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.OwnerDisplayName, tt.PostCount
)
SELECT 
    pd.Title,
    pd.Body,
    pd.OwnerDisplayName,
    pd.PostCount,
    pd.CommentCount,
    pd.LastEditDate
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.PostCount DESC, pd.LastEditDate DESC;
