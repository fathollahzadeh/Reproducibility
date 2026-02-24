WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title,
           p.ViewCount,
           p.CreationDate,
           p.Tags,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
      AND p.ViewCount > 1000
)

SELECT rp.PostId, 
       rp.Title, 
       rp.ViewCount, 
       rp.CreationDate, 
       rp.Tags, 
       rp.OwnerDisplayName,
       ph.Comment AS LastEditComment,
       ph.CreationDate AS LastEditDate
FROM RankedPosts rp
LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
WHERE rp.Rank <= 3
      AND ph.PostHistoryTypeId IN (4, 5) 
      AND ph.CreationDate = (SELECT MAX(ph2.CreationDate)
                              FROM PostHistory ph2
                              WHERE ph2.PostId = rp.PostId
                                AND ph2.PostHistoryTypeId IN (4, 5))
ORDER BY rp.Tags, rp.ViewCount DESC;