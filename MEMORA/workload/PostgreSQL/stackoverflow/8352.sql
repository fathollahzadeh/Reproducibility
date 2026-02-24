WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.rn = 1
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CommentCount,
    pht.Name AS PostHistoryType,
    ph.CreationDate AS HistoryCreationDate,
    ph.UserDisplayName AS HistoryEditor
FROM RecentPosts rp
LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE ph.CreationDate = (
    SELECT MAX(ph2.CreationDate)
    FROM PostHistory ph2
    WHERE ph2.PostId = rp.PostId
)
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 10;
