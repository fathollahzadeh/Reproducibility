
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, u.Reputation
)

SELECT 
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.ViewCount,
    PM.Score,
    PM.AnswerCount,
    PM.CommentCount,
    PM.OwnerReputation,
    PM.LastEditDate,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = PM.PostId) AS VoteCount
FROM 
    PostMetrics PM
ORDER BY 
    PM.ViewCount DESC
LIMIT 100;
