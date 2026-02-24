WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pa.AnswerCount, 0) AS AnswerCount,
        u.Reputation,
        pt.Name AS PostTypeName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) pa ON p.Id = pa.ParentId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.TagCount,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.AnswerCount,
        tp.Reputation,
        tp.PostTypeName,
        ROW_NUMBER() OVER (ORDER BY tp.Reputation DESC, tp.CreationDate DESC) AS Rank
    FROM 
        TaggedPosts tp
    WHERE 
        tp.TagCount > 0
)

SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.TagCount,
    t.CommentCount,
    t.AnswerCount,
    t.Reputation,
    t.PostTypeName
FROM 
    TopPosts t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;