
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.ViewCount, p.CreationDate, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT u.Id AS UserId, 
           SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularUsers AS (
    SELECT ur.UserId, ur.TotalBadges, u.Reputation
    FROM UserReputation ur
    INNER JOIN Users u ON ur.UserId = u.Id
    WHERE ur.TotalBadges > 0 AND u.Reputation > 1000
)
SELECT rp.Title, rp.ViewCount, rp.CreationDate, pu.TotalBadges, pu.Reputation
FROM RankedPosts rp
LEFT JOIN PopularUsers pu ON rp.Id = (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.Id AND AcceptedAnswerId IS NOT NULL)
WHERE rp.PostRank = 1
ORDER BY pu.Reputation DESC, rp.ViewCount DESC
LIMIT 10;
