
WITH RECURSIVE RecentPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
RankedUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyEarned,
           DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT p.Id) > 0
),
LatestPostHistory AS (
    SELECT ph.PostId, ph.UserId, ph.CreationDate,
           MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastEditedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6, 10) 
),
AggregatedData AS (
    SELECT p.Id AS PostId, p.Title, p.OwnerUserId, p.CreationDate,
           COALESCE(rp.rn, 0) AS RecentPostRank,
           lph.UserId AS LastEditorId, lph.LastEditedDate,
           COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN RecentPosts rp ON p.Id = rp.Id
    LEFT JOIN LatestPostHistory lph ON p.Id = lph.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate, rp.rn, lph.UserId, lph.LastEditedDate
)
SELECT ru.DisplayName, ru.Reputation, ru.PostCount, ru.TotalBountyEarned,
       ad.PostId, ad.Title, ad.CreationDate, ad.RecentPostRank, ad.LastEditorId, ad.LastEditedDate,
       ad.CommentCount
FROM RankedUsers ru
JOIN AggregatedData ad ON ru.Id = ad.OwnerUserId
WHERE ru.UserRank <= 10 
ORDER BY ru.Reputation DESC, ad.CreationDate DESC;
