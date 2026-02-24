WITH PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount,
        uch.DisplayName AS OwnerDisplayName,
        u.DisplayName AS LastEditorDisplayName,
        p.LastEditDate
    FROM
        Posts p
    LEFT JOIN
        Users uch ON p.OwnerUserId = uch.Id
    LEFT JOIN
        Users u ON p.LastEditorUserId = u.Id
)
SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.AnswerCount,
    ps.OwnerDisplayName,
    ps.LastEditorDisplayName,
    ps.LastEditDate,
    pht.Name AS PostHistoryType
FROM
    PostStatistics ps
LEFT JOIN
    PostHistory ph ON ph.PostId = ps.PostId
LEFT JOIN
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100;