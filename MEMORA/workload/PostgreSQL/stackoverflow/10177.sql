
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(v.VoteCount, 0) AS VoteCount,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpVotes,
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownVotes
FROM 
    Posts p
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON p.Id = c.PostId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS VoteCount,
        VoteTypeId
    FROM 
        Votes
    GROUP BY 
        PostId, VoteTypeId
) v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, c.CommentCount, v.VoteCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
