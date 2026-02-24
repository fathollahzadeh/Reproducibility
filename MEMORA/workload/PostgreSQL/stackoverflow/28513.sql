WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(a.AnswerCount, 0) AS TotalAnswers,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation, a.AnswerCount
),

TopTaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.TotalAnswers,
        rp.CommentCount,
        rp.TagRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT 
             p.Id,
             UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS TagName
         FROM 
             Posts p
         WHERE 
             p.PostTypeId = 1) t ON rp.PostId = t.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.OwnerDisplayName, 
        rp.OwnerReputation, rp.TotalAnswers, rp.CommentCount, rp.TagRank
)

SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    ViewCount,
    OwnerDisplayName,
    OwnerReputation,
    TotalAnswers,
    CommentCount,
    TagRank,
    Tags
FROM 
    TopTaggedPosts
WHERE 
    TagRank <= 5  
ORDER BY 
    CreationDate DESC;