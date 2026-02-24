SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.LastActivityDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(voteCount.UpVotes, 0) AS UpVotes,
    COALESCE(voteCount.DownVotes, 0) AS DownVotes,
    COALESCE(c.commentCount, 0) AS CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
) voteCount ON p.Id = voteCount.PostId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS commentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) c ON p.Id = c.PostId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01' 
ORDER BY 
    p.LastActivityDate DESC
LIMIT 100;