
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PopularUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT p.Id) > 5
),
PostHistoryDetails AS (
    SELECT ph.PostId, 
           STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
           MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT pu.DisplayName AS UserName, 
       rp.Title AS MostRecentPost, 
       rp.CreationDate AS PostDate, 
       pu.UpVotes, 
       pu.DownVotes, 
       COALESCE(phd.HistoryTypes, 'No Edits') AS EditHistory,
       (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = rp.Id) AS RelatedPostCount
FROM RankedPosts rp
JOIN PopularUsers pu ON rp.OwnerUserId = pu.Id
LEFT JOIN PostHistoryDetails phd ON rp.Id = phd.PostId
WHERE rp.rn = 1
ORDER BY pu.Reputation DESC, rp.CreationDate DESC;
