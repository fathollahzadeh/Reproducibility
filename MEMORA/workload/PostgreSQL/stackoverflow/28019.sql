
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
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
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    CASE 
        WHEN rp.AnswerCount > 0 THEN 'Answered'
        WHEN rp.LastActivityDate <= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' THEN 'Inactive'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
WHERE 
    rp.TagRank <= 3  
ORDER BY 
    rp.Tags, rp.CreationDate DESC;
