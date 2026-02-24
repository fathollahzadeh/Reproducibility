
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.CommentCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.CommentCount, u.DisplayName
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    CommentCount,
    Author,
    TotalComments
FROM 
    PostStats
ORDER BY 
    Score DESC
LIMIT 100;
