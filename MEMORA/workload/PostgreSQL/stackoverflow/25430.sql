
WITH FilteredPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.Body, 
           p.Tags,
           p.CreationDate,
           u.DisplayName AS OwnerDisplayName,
           COUNT(c.Id) AS CommentCount,
           ARRAY_AGG(DISTINCT t.TagName) AS UniqueTags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE p.CreationDate >= DATE('2024-10-01') - INTERVAL '3 months'
      AND p.ViewCount > 100
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),

RelevantHistories AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.CreationDate AS HistoryCreationDate,
           ph.UserId,
           pt.Name AS PostHistoryTypeName
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate >= DATE('2024-10-01') - INTERVAL '1 month'
      AND ph.PostHistoryTypeId IN (10, 11, 24)  
)

SELECT fp.Id AS PostId,
       fp.Title,
       fp.Body,
       fp.OwnerDisplayName,
       fp.CommentCount,
       fp.UniqueTags,
       COUNT(CASE WHEN rh.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
       COUNT(CASE WHEN rh.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
       MAX(rh.HistoryCreationDate) AS LastActionDate
FROM FilteredPosts fp
LEFT JOIN RelevantHistories rh ON fp.Id = rh.PostId
GROUP BY fp.Id, fp.Title, fp.Body, fp.OwnerDisplayName, fp.CommentCount, fp.UniqueTags
ORDER BY fp.CommentCount DESC, LastActionDate DESC
LIMIT 50;
