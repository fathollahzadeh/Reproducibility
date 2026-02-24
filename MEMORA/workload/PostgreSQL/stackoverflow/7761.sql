WITH PopularPosts AS (
    SELECT p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1
    AND p.Score > 10
    ORDER BY p.ViewCount DESC
    LIMIT 20
),
PostVotes AS (
    SELECT p.Id AS PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId IN (1, 2)
    GROUP BY p.Id
),
PostHistoryData AS (
    SELECT ph.PostId, 
           COUNT(ph.Id) AS EditCount,
           MAX(ph.CreationDate) AS LastEditDate,
           STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT pp.Id AS PostId,
       pp.Title,
       pp.ViewCount,
       pp.Score,
       pp.CreationDate,
       pp.OwnerDisplayName,
       pv.UpVotes,
       pv.DownVotes,
       phd.EditCount,
       phd.LastEditDate,
       phd.EditTypes
FROM PopularPosts pp
LEFT JOIN PostVotes pv ON pp.Id = pv.PostId
LEFT JOIN PostHistoryData phd ON pp.Id = phd.PostId
ORDER BY pp.ViewCount DESC, pp.Score DESC;
