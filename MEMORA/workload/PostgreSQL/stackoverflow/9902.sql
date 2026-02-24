
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        Rank
    FROM RankedPosts
    WHERE Rank <= 3
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.OwnerDisplayName,
    bh.Name AS BadgeName,
    bh.Date AS BadgeDate
FROM TopPosts tp
LEFT JOIN Badges bh ON tp.OwnerDisplayName = CAST(bh.UserId AS TEXT)
WHERE bh.Class = 1 OR bh.Class = 2
ORDER BY tp.ViewCount DESC, tp.CreationDate DESC
LIMIT 10;
