
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryCreationDate
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    PostHistory ph ON p.Id = ph.PostId
WHERE
    p.CreationDate >= '2022-01-01' 
GROUP BY
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount,
    u.Id, u.DisplayName, u.Reputation,
    ph.PostHistoryTypeId, ph.CreationDate
ORDER BY
    p.CreationDate DESC;
