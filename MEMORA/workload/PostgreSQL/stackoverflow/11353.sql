SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    MAX(v.VoteCount) AS MaxVoteCount,
    MIN(v.VoteCount) AS MinVoteCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC;