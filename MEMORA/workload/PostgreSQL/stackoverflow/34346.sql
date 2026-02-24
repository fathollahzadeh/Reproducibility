WITH RecentPosts AS (
    SELECT p.Id AS PostId, 
           p.OwnerUserId, 
           p.Title, 
           p.CreationDate, 
           p.LastActivityDate,
           p.Score, 
           p.AnswerCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

UserDetails AS (
    SELECT u.Id AS UserId,
           u.DisplayName, 
           u.Reputation, 
           COALESCE(badge_count.badge_count, 0) AS BadgeCount, 
           COALESCE(vote_count.votes, 0) AS VoteCount
    FROM Users u
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS badge_count
        FROM Badges 
        GROUP BY UserId
    ) AS badge_count ON u.Id = badge_count.UserId
    LEFT JOIN (
        SELECT v.UserId, COUNT(*) AS votes
        FROM Votes v
        GROUP BY v.UserId
    ) AS vote_count ON u.Id = vote_count.UserId
),

PostActivity AS (
    SELECT ph.PostId, 
           MAX(ph.CreationDate) AS LastEditDate,
           COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount,
           COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Id END) AS ReopenCount,
           COUNT(DISTINCT ph.Id) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),

FilteredPosts AS (
    SELECT rp.PostId, 
           ud.DisplayName, 
           ud.Reputation, 
           ud.BadgeCount, 
           ud.VoteCount, 
           pa.LastEditDate, 
           pa.CloseCount, 
           pa.ReopenCount, 
           pa.EditCount
    FROM RecentPosts rp
    JOIN UserDetails ud ON rp.OwnerUserId = ud.UserId
    LEFT JOIN PostActivity pa ON rp.PostId = pa.PostId
    WHERE rp.rn = 1 
)

SELECT fp.PostId, 
       fp.DisplayName, 
       fp.Reputation, 
       fp.BadgeCount, 
       fp.VoteCount, 
       fp.LastEditDate,
       fp.CloseCount,
       fp.ReopenCount,
       fp.EditCount,
       CASE 
           WHEN fp.CloseCount > 0 THEN 'Closed' 
           WHEN fp.ReopenCount > 0 THEN 'Reopened' 
           ELSE 'Active' 
       END AS PostStatus
FROM FilteredPosts fp
WHERE (fp.VoteCount > 10 OR fp.Reputation > 100)
ORDER BY fp.Reputation DESC, 
         fp.CloseCount DESC, 
         fp.EditCount DESC
LIMIT 50;