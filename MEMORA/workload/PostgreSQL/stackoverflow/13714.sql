SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(vote_counts.UpVotes, 0) AS UpVotes,
    COALESCE(vote_counts.DownVotes, 0) AS DownVotes,
    COALESCE(comment_counts.CommentCount, 0) AS CommentCount,
    p.CreationDate,
    p.LastActivityDate
FROM 
    Posts p
LEFT JOIN 
    (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vote_counts ON p.Id = vote_counts.PostId
LEFT JOIN 
    (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) comment_counts ON p.Id = comment_counts.PostId
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;