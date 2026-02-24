
WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END) AS UpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1.0 ELSE 0.0 END) AS DownVotes
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, u.Reputation
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.Score,
    pa.AnswerCount,
    pa.CommentCount,
    pa.OwnerReputation,
    pa.VoteCount,
    pa.UpVotes,
    pa.DownVotes
FROM 
    PostActivity pa
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC;
