SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COALESCE(vote_counts.UpVotes, 0) AS UpVotes,
    COALESCE(vote_counts.DownVotes, 0) AS DownVotes,
    COALESCE(comment_counts.CommentCount, 0) AS CommentCount,
    COALESCE(user_stats.UserReputation, 0) AS UserReputation,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
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
    ) AS vote_counts ON p.Id = vote_counts.PostId
LEFT JOIN 
    (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) AS comment_counts ON p.Id = comment_counts.PostId
LEFT JOIN 
    (
        SELECT 
            u.Id,
            SUM(u.Reputation) AS UserReputation
        FROM 
            Users u
        GROUP BY 
            u.Id
    ) AS user_stats ON u.Id = user_stats.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
ORDER BY 
    p.CreationDate DESC
LIMIT 100;