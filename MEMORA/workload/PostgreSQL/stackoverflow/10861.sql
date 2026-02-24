SELECT
    p.Id AS PostId,
    p.Title,
    p.PostTypeId,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
    COUNT(c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    MAX(ph.CreationDate) AS LastEditDate,
    COUNT(DISTINCT ph.Id) AS EditCount
FROM
    Posts p
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
WHERE
    p.CreationDate >= '2023-01-01' 
GROUP BY
    p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, u.DisplayName
ORDER BY
    p.Score DESC, p.ViewCount DESC;