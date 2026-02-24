WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.LastActivityDate, p.Score,
           p.ViewCount, p.AnswerCount, p.CommentCount, p.AcceptedAnswerId, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserStats AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.Views, 
           COUNT(DISTINCT b.Id) AS BadgeCount, 
           SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostCount,
           SUM(CASE WHEN v.UserId = u.Id AND v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
TopRecentPosts AS (
    SELECT rp.*, u.DisplayName AS OwnerDisplayName, us.Reputation AS OwnerReputation, us.BadgeCount
    FROM RecentPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    JOIN UserStats us ON u.Id = us.Id
    WHERE rp.rn = 1 
)
SELECT trp.Title, trp.OwnerDisplayName, trp.OwnerReputation, trp.CreationDate, 
       trp.Score, trp.ViewCount, trp.AnswerCount, trp.CommentCount, 
       trp.BadgeCount,
       COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = trp.Id), 0) AS TotalComments
FROM TopRecentPosts trp
ORDER BY trp.Score DESC, trp.ViewCount DESC;