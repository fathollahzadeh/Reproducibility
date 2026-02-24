
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
    u.CreationDate AS UserCreationDate,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    AVG(COALESCE(v.BountyAmount, 0)) AS AverageBountyAmount
FROM
    Posts p
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
GROUP BY
    p.Id,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.Id,
    u.DisplayName,
    u.Reputation,
    u.CreationDate
ORDER BY
    p.ViewCount DESC, p.Score DESC
LIMIT 100;
