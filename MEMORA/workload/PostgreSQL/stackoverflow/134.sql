
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    WHERE p.PostTypeId = 1 
      AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(v.Id) >= 1
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageScore
    FROM Comments c
    GROUP BY c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pu.TotalUpvotes,
    pu.TotalDownvotes,
    cs.CommentCount,
    cs.AverageScore
FROM RankedPosts rp
LEFT JOIN PopularUsers pu ON rp.OwnerUserId = pu.UserId
LEFT JOIN CommentStats cs ON rp.PostId = cs.PostId
WHERE rp.RN = 1
  AND pu.TotalUpvotes IS NOT NULL
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
