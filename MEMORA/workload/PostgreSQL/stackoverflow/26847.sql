WITH RelevantPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Tags, 
           p.CreationDate, 
           p.ViewCount, 
           u.DisplayName AS OwnerName,
           ph.Comment AS LastEditComment,
           ph.CreationDate AS LastEditDate,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.PostTypeId = 1 
    AND ph.PostHistoryTypeId IN (4, 5, 6) 
),
LatestEdits AS (
    SELECT PostId, Title, Tags, CreationDate, ViewCount, OwnerName, LastEditComment, LastEditDate
    FROM RelevantPosts
    WHERE rn = 1
)
SELECT r.OwnerName, 
       COUNT(*) AS TotalQuestions, 
       AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - r.CreationDate)) / 3600) AS AvgHoursSinceCreated,
       SUM(r.ViewCount) AS TotalViewCount,
       STRING_AGG(DISTINCT r.Title, ', ') AS EditedTitles,
       STRING_AGG(DISTINCT r.Tags, ', ') AS UniqueTags,
       COUNT(DISTINCT r.LastEditComment) AS DistinctEditComments
FROM LatestEdits r
GROUP BY r.OwnerName
ORDER BY TotalQuestions DESC
LIMIT 10;