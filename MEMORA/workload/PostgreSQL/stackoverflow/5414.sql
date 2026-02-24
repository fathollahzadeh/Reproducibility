WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
           (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE u.Reputation > 500
),
TopPosts AS (
    SELECT Id, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, OwnerUserId, UpVotes, DownVotes
    FROM RankedPosts
    WHERE Rank <= 10
),
UserBadges AS (
    SELECT b.UserId, COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostHistorySummary AS (
    SELECT ph.PostId, COUNT(*) AS EditCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.PostId
)
SELECT tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount, 
       ub.BadgeCount, phs.EditCount,
       CASE 
           WHEN tp.UpVotes > tp.DownVotes THEN 'Positive'
           WHEN tp.UpVotes < tp.DownVotes THEN 'Negative'
           ELSE 'Neutral'
       END AS VoteSentiment
FROM TopPosts tp
LEFT JOIN UserBadges ub ON tp.OwnerUserId = ub.UserId
LEFT JOIN PostHistorySummary phs ON tp.Id = phs.PostId
ORDER BY tp.Score DESC, tp.ViewCount DESC;