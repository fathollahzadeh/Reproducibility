
WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
RecentPostHistories AS (
    SELECT ph.PostId,
           ph.CreationDate AS HistoryDate,
           p.Title,
           ph.UserDisplayName,
           ph.Comment,
           ph.Text,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 13) 
      AND ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostTags AS (
    SELECT p.Id AS PostId,
           STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS tag ON true
    JOIN Tags t ON t.TagName = TRIM(tag)
    GROUP BY p.Id
)
SELECT rp.Id AS PostId,
       rp.Title,
       rp.CreationDate,
       rp.Score,
       rp.ViewCount,
       rp.OwnerDisplayName,
       COALESCE(pt.Tags, 'No Tags') AS Tags,
       CASE WHEN rph.HistoryRank IS NOT NULL THEN rph.HistoryDate END AS LastHistoryDate,
       CASE WHEN rph.HistoryRank IS NOT NULL THEN rph.Comment END AS LastComment,
       CASE WHEN rph.HistoryRank IS NOT NULL THEN rph.Text END AS LastText
FROM RankedPosts rp
LEFT JOIN RecentPostHistories rph ON rp.Id = rph.PostId AND rph.HistoryRank = 1
LEFT JOIN PostTags pt ON rp.Id = pt.PostId
WHERE rp.Rank <= 5
ORDER BY rp.Score DESC, rp.CreationDate DESC;
