
WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
FilteredPosts AS (
    SELECT rp.Id, rp.Title, rp.CreationDate, rp.ViewCount,
           rp.CommentCount, rp.UpVotes, rp.DownVotes
    FROM RankedPosts rp
    WHERE rp.rn = 1
      AND rp.ViewCount > 100
      AND (rp.UpVotes - rp.DownVotes) > 10
),
UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
)
SELECT fp.Title, fp.ViewCount, fp.CommentCount, ub.BadgeCount,
       CASE 
           WHEN ub.BadgeCount IS NULL THEN 'No Badges'
           WHEN ub.BadgeCount >= 10 THEN 'Veteran'
           ELSE 'Newbie'
       END AS UserStatus
FROM FilteredPosts fp
LEFT JOIN Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.Id)
LEFT JOIN UserBadges ub ON ub.UserId = u.Id
ORDER BY fp.ViewCount DESC
LIMIT 50;
