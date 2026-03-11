
CREATE TEMP TABLE IF NOT EXISTS top_post_ids AS
SELECT Id
FROM Posts
WHERE PostTypeId = 1
ORDER BY CreationDate DESC
LIMIT 10;

SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       u.DisplayName AS OwnerDisplayName,
       p.Score,
       p.ViewCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN top_post_ids t ON p.id = t.id
ORDER BY p.CreationDate DESC;