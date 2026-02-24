
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 month' 
    GROUP BY p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM RankedPosts
    WHERE Rank <= 5
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    COALESCE(phc.HistoryCount, 0) AS TotalHistoryRecords
FROM TopPosts tp
LEFT JOIN PostHistoryCounts phc ON tp.PostId = phc.PostId
ORDER BY tp.ViewCount DESC;
