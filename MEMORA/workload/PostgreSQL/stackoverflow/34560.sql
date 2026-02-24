WITH RecursiveVoteCounts AS (
    SELECT p.Id AS PostId,
           COUNT(v.Id) AS TotalVotes,
           SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY p.Id
),
UserBadges AS (
    SELECT u.Id AS UserId,
           COUNT(b.Id) AS TotalBadges,
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostModificationHistory AS (
    SELECT ph.PostId,
           ph.CreationDate,
           PH.UserDisplayName,
           ph.Comment,
           p.Title,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ModificationRank
    FROM PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 10)  
)

SELECT u.DisplayName,
       COALESCE(b.TotalBadges, 0) AS UserBadgeCount,
       COALESCE(b.BadgeNames, 'No Badges') AS BadgeDetails,
       p.Title,
       pmh.CreationDate AS LastModified,
       pmh.Comment AS ModificationComment,
       rvc.TotalVotes,
       rvc.UpVotes,
       rvc.DownVotes
FROM Users u
LEFT JOIN UserBadges b ON u.Id = b.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN RecursiveVoteCounts rvc ON p.Id = rvc.PostId
LEFT JOIN PostModificationHistory pmh ON p.Id = pmh.PostId AND pmh.ModificationRank = 1
WHERE u.Reputation > 1000
ORDER BY p.Score DESC, rvc.TotalVotes DESC;