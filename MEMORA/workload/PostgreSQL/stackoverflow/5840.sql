SELECT 
    u.DisplayName AS User,
    p.Title AS Post_Title,
    p.CreationDate AS Post_Creation_Date,
    p.Score AS Post_Score,
    COALESCE(avg_comments.avg_comment_score, 0) AS Average_Comment_Score,
    COALESCE(vote_counts.UpVotes, 0) AS Total_UpVotes,
    COALESCE(vote_counts.DownVotes, 0) AS Total_DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (
        SELECT 
            c.PostId,
            AVG(c.Score) AS avg_comment_score
        FROM 
            Comments c
        GROUP BY 
            c.PostId
    ) avg_comments ON p.Id = avg_comments.PostId
LEFT JOIN 
    (
        SELECT 
            v.PostId,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes v
        GROUP BY 
            v.PostId
    ) vote_counts ON p.Id = vote_counts.PostId
WHERE 
    p.PostTypeId = 1
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
