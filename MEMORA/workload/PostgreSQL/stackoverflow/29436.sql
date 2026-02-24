WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostID,
        Title,
        CreationDate,
        Body,
        Tags,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
),
TaggedPosts AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.VoteCount,
        unnest(string_to_array(tp.Tags, ',')) AS TagName
    FROM 
        TopPosts tp
)
SELECT 
    tp.PostID,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    COUNT(DISTINCT tp.TagName) AS UniqueTagCount
FROM 
    TaggedPosts tp
GROUP BY 
    tp.PostID, tp.Title, tp.OwnerDisplayName, tp.CommentCount, tp.VoteCount
ORDER BY 
    UniqueTagCount DESC, VoteCount DESC
LIMIT 5;