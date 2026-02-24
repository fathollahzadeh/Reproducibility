WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, 0 AS Level
    FROM Users
    WHERE Id IN (SELECT UserId FROM Badges WHERE Class = 1) 

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, uh.Level + 1
    FROM Users u
    INNER JOIN UserHierarchy uh ON u.Id = uh.Id + 1 
)

SELECT
    p.Id AS PostId,
    p.Title,
    p.Body,
    u.DisplayName AS PostCreator,
    u.Reputation AS CreatorReputation,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(b.Date) AS LastBadgeDate,
    ARRAY_AGG(DISTINCT uh.DisplayName) AS GoldBadgeHolders
FROM Posts p
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1
LEFT JOIN UserHierarchy uh ON u.Id = uh.Id 

WHERE 
    p.CreationDate >= '2023-01-01' 
    AND p.PostTypeId = 1 
    AND p.Score > 0 
GROUP BY 
    p.Id, p.Title, p.Body, u.DisplayName, u.Reputation
HAVING 
    COUNT(c.Id) > 5 
    AND MAX(b.Date) IS NOT NULL 
ORDER BY 
    CreatorReputation DESC, PostId DESC;