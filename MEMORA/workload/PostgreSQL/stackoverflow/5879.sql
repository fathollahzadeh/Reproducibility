
WITH RecentPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.ViewCount, 
           COALESCE(a.Score, 0) AS AcceptedAnswerScore, 
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) AS VoteCount,
           p.OwnerUserId
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, AcceptedAnswerScore, p.OwnerUserId
),
RankedPosts AS (
    SELECT rp.*, 
           ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC, rp.VoteCount DESC, rp.AcceptedAnswerScore DESC) AS Rank
    FROM RecentPosts rp
)
SELECT r.PostId, 
       r.Title, 
       r.CreationDate, 
       r.ViewCount, 
       r.CommentCount, 
       r.VoteCount, 
       r.Rank, 
       u.DisplayName AS OwnerDisplayName, 
       u.Reputation AS OwnerReputation 
FROM RankedPosts r
JOIN Users u ON r.OwnerUserId = u.Id
WHERE r.Rank <= 10
ORDER BY r.Rank;
