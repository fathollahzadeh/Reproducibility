
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags, u.DisplayName
), 
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Body,
        Tags,
        OwnerDisplayName,
        AnswerCount,
        CommentCount,
        VoteCount,
        PostRank
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.AnswerCount,
    p.CommentCount,
    p.VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags 
FROM 
    FilteredPosts p
LEFT JOIN 
    Tags t ON t.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, ', '))) 
GROUP BY 
    p.PostId, p.Title, p.OwnerDisplayName, p.CreationDate, p.AnswerCount, p.CommentCount, p.VoteCount
ORDER BY 
    p.CreationDate DESC;
