
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT bh.Id) AS EditCount,
        MAX(p.CreationDate) AS PostCreationDate,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostTypeId,
    ps.CommentCount,
    ps.VoteCount,
    ps.EditCount,
    ps.PostCreationDate,
    ps.LastActivityDate,
    EXTRACT(EPOCH FROM (ps.LastActivityDate - ps.PostCreationDate)) AS ActivityDuration
FROM 
    PostStats ps
ORDER BY 
    ps.LastActivityDate DESC
LIMIT 100;
