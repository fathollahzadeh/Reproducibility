WITH PostTags AS (
    SELECT p.Id AS PostId,
           STRING_AGG(t.TagName, ', ') AS TagsAggregated,
           p.OwnerUserId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           p.AcceptedAnswerId,
           p.CommentCount,
           p.FavoriteCount
    FROM Posts p
    LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId, p.CommentCount, p.FavoriteCount
),
TopUsers AS (
    SELECT u.Id,
           u.DisplayName,
           SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY u.Id, u.DisplayName
    ORDER BY TotalScore DESC
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           ph.UserDisplayName AS EditorName,
           ph.CreationDate AS EditDate,
           p.Title,
           ph.Comment,
           ph.Text
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  
)

SELECT pt.PostId,
       pt.Title,
       pt.TagsAggregated,
       pt.OwnerUserId,
       u.DisplayName AS OwnerDisplayName,
       u.Reputation AS OwnerReputation,
       pt.CreationDate,
       pt.Score,
       pt.ViewCount,
       pt.AcceptedAnswerId,
       pt.CommentCount,
       pt.FavoriteCount,
       tu.TotalScore AS TopUserScore,
       phed.EditorName,
       phed.EditDate,
       phed.Comment AS EditComment,
       phed.Text AS NewEditValue
FROM PostTags pt
JOIN Users u ON pt.OwnerUserId = u.Id
LEFT JOIN TopUsers tu ON u.Id = tu.Id
LEFT JOIN PostHistoryDetails phed ON pt.PostId = phed.PostId
ORDER BY pt.Score DESC, pt.ViewCount DESC;