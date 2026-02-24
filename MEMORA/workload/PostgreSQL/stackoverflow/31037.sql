
WITH RECURSIVE RecursiveUserCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        0 AS Level
    FROM Users
    WHERE Id = 1  

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        Level + 1
    FROM Users AS u
    INNER JOIN RecursiveUserCTE AS r ON r.Id = u.Id
    WHERE Level < 5  
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpvoteCount,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownvoteCount,
    CASE 
        WHEN p.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Older Post'
        ELSE 'Recent Post'
    END AS PostAge,
    RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS ScoreRank,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(u.Location, 'Location not specified') AS UserLocation

FROM Posts p
LEFT JOIN Users u ON p.OwnerUserId = u.Id
JOIN RecursiveUserCTE r ON u.Id = r.Id
WHERE p.ViewCount > 50  
AND p.Score IS NOT NULL
GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, u.Reputation, u.Location
ORDER BY p.CreationDate DESC
LIMIT 100;
