SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(vote_counts.UpVotes, 0) AS UpVoteCount,
    COALESCE(vote_counts.DownVotes, 0) AS DownVoteCount,
    COALESCE(c_counts.CommentCount, 0) AS CommentCount,
    COALESCE(badge_counts.BadgeCount, 0) AS UserBadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM 
        Votes
     GROUP BY 
        PostId) vote_counts ON p.Id = vote_counts.PostId
LEFT JOIN 
    (SELECT 
        PostId,
        COUNT(Id) AS CommentCount
     FROM 
        Comments
     GROUP BY 
        PostId) c_counts ON p.Id = c_counts.PostId
LEFT JOIN 
    (SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
     FROM 
        Badges
     GROUP BY 
        UserId) badge_counts ON u.Id = badge_counts.UserId
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC
LIMIT 100;