WITH Benchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS UserReputation,
        u.CreationDate AS UserCreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        (
            SELECT COUNT(*) 
            FROM PostHistory ph 
            WHERE ph.PostId = p.Id
        ) AS EditCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.Reputation, p.Title, p.CreationDate, p.Score, p.ViewCount, u.CreationDate
)
SELECT 
    *,
    (CASE 
        WHEN UserReputation > 1000 THEN 'High Reputation'
        WHEN UserReputation BETWEEN 501 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END) AS ReputationCategory
FROM 
    Benchmark
ORDER BY 
    CreationDate DESC, Score DESC;
