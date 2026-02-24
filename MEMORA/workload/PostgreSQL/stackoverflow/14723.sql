WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(ans.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts ans ON p.Id = ans.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.LastActivityDate, p.ViewCount
)
SELECT 
    rp.PostId, 
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Rank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 100  
ORDER BY 
    rp.Rank;