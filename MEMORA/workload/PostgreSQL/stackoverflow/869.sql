
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.Score, p.OwnerUserId, p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), UserStats AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           COUNT(p.Id) AS TotalPosts,
           SUM(u.UpVotes) AS TotalUpVotes,
           SUM(u.DownVotes) AS TotalDownVotes,
           COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
           COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
           COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
), FilteredPosts AS (
    SELECT rp.Id, rp.Title, rp.Score, u.DisplayName, us.TotalPosts
    FROM RankedPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    JOIN UserStats us ON u.Id = us.UserId
    WHERE rp.PostRank <= 5 AND us.TotalPosts > 10
)
SELECT fp.Title, fp.Score, fp.DisplayName, fp.TotalPosts,
       CASE 
           WHEN fp.Score IS NULL THEN 'No Score'
           ELSE CASE 
                WHEN fp.Score > 100 THEN 'High Score'
                WHEN fp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
                ELSE 'Low Score'
           END
       END AS ScoreCategory
FROM FilteredPosts fp
LEFT JOIN Comments c ON c.PostId = fp.Id
WHERE c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
GROUP BY fp.Title, fp.Score, fp.DisplayName, fp.TotalPosts
ORDER BY fp.Score DESC
LIMIT 10;
