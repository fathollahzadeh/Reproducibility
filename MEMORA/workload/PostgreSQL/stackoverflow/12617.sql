WITH AggregatedData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= '2023-01-01 00:00:00' 
    GROUP BY 
        p.Id, p.Title, u.DisplayName
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    CommentCount,
    VoteCount,
    LastEditDate
FROM 
    AggregatedData
ORDER BY 
    VoteCount DESC, CommentCount DESC
LIMIT 100;