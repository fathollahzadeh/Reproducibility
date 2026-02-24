
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        p.ViewCount,
        p.Score,
        MAX(h.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1  
    LEFT JOIN 
        Comments c ON p.Id = c.PostId  
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId  
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.Title, pt.Name, p.ViewCount, p.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostType,
    ps.AnswerCount,
    ps.CommentCount,
    ps.ViewCount,
    ps.Score,
    ps.LastEditDate
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
