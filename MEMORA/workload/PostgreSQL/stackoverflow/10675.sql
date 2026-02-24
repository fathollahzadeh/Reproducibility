SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(v.UpVotesCount, 0) AS UpVotes,
    COALESCE(v.DownVotesCount, 0) AS DownVotes,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' 
ORDER BY 
    p.CreationDate DESC
LIMIT 100;