SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COALESCE(VoteCounts.UpVotes, 0) AS UpVoteCount,
    COALESCE(VoteCounts.DownVotes, 0) AS DownVoteCount,
    COALESCE(BadgeCounts.BadgeCount, 0) AS UserBadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    (SELECT 
         PostId,
         SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
         SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM 
         Votes
     GROUP BY 
         PostId) VoteCounts ON P.Id = VoteCounts.PostId
LEFT JOIN 
    (SELECT 
         UserId,
         COUNT(*) AS BadgeCount
     FROM 
         Badges
     GROUP BY 
         UserId) BadgeCounts ON U.Id = BadgeCounts.UserId
ORDER BY 
    P.CreationDate DESC
LIMIT 100;