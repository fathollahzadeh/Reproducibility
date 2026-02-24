
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND  
        p.Tags IS NOT NULL AND 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 YEAR'  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.LastActivityDate, u.DisplayName
),

RankedPosts AS (
    SELECT 
        f.*,
        RANK() OVER (ORDER BY f.CommentCount DESC, f.AnswerCount DESC) AS Rank
    FROM 
        FilteredPosts f
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Rank,
    STRING_AGG(b.Name, ', ') AS Badges 
FROM 
    RankedPosts rp
LEFT JOIN 
    Badges b ON rp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = b.UserId)
WHERE 
    rp.Rank <= 10  
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.LastActivityDate, rp.OwnerDisplayName, rp.CommentCount, rp.AnswerCount, rp.Rank
ORDER BY 
    rp.Rank;
