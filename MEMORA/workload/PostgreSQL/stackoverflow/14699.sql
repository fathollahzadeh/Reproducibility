SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(vote_count.upvotes, 0) AS UpVotes,
    COALESCE(vote_count.downvotes, 0) AS DownVotes,
    p.CommentCount,
    p.AnswerCount,
    p.CreationDate
FROM 
    Posts p
LEFT JOIN 
    (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vote_count ON p.Id = vote_count.PostId
ORDER BY 
    p.ViewCount DESC
LIMIT 10;