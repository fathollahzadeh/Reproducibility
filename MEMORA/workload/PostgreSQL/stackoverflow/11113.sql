SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    COALESCE(SUM(voteTypeVoteCount), 0) AS TotalVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS voteTypeVoteCount FROM Votes GROUP BY PostId) AS VoteSummary ON p.Id = VoteSummary.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalVotes DESC, PostCount DESC
LIMIT 100;