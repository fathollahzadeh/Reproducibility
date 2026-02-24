
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM
    Posts p
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Users U ON p.OwnerUserId = U.Id
WHERE
    p.CreationDate >= '2023-01-01'  
GROUP BY
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, U.DisplayName, U.Reputation
ORDER BY
    p.CreationDate DESC
LIMIT 100;
