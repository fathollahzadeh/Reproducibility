
WITH RankedPosts AS (
    SELECT p.Id AS PostId, p.Title, p.Score, p.ViewCount, p.PostTypeId,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
      AND p.Score > 0
),
TopPosts AS (
    SELECT r.PostId, r.Title, r.Score, r.ViewCount, pt.Name AS PostTypeName
    FROM RankedPosts r
    JOIN PostTypes pt ON r.Rank <= 5 AND r.PostTypeId = pt.Id
)
SELECT p.OwnerDisplayName, 
       COUNT(DISTINCT c.Id) AS CommentCount, 
       COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
       AVG(u.Reputation) AS AverageReputation
FROM TopPosts tp
LEFT JOIN Posts p ON tp.PostId = p.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
LEFT JOIN Users u ON p.OwnerUserId = u.Id
GROUP BY p.OwnerDisplayName
ORDER BY TotalBounties DESC, CommentCount DESC
LIMIT 10;
