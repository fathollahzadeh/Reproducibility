WITH Benchmarking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
)
SELECT 
    *,
    (EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - CreationDate)) / 3600) AS HoursSinceCreation,
    (SELECT COUNT(*) FROM Posts WHERE AcceptedAnswerId = PostId) AS AcceptedAnswers
FROM 
    Benchmarking
ORDER BY 
    ViewCount DESC, Score DESC
LIMIT 100;