WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
           u.DisplayName AS OwnerDisplayName,
           COALESCE(p.AnswerCount, 0) AS AnswerCount,
           COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName, p.Score, p.AnswerCount
),
HighScorePosts AS (
    SELECT r.OwnerUserId, r.OwnerDisplayName, COUNT(r.Id) AS PostCount, SUM(r.Score) AS TotalScore
    FROM RankedPosts r
    WHERE r.Rank = 1
    GROUP BY r.OwnerUserId, r.OwnerDisplayName
)
SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, 
       hs.PostCount, hs.TotalScore
FROM Users u
JOIN HighScorePosts hs ON u.Id = hs.OwnerUserId
WHERE u.Reputation > 1000
ORDER BY hs.TotalScore DESC, hs.PostCount DESC
LIMIT 10;
