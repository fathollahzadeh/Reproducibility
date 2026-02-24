
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName AS OwnerName, 
           COUNT(c.Id) AS CommentCount, COUNT(DISTINCT v.UserId) AS VoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT Id, Title, CreationDate, Score, OwnerName, CommentCount, VoteCount,
           RANK() OVER (ORDER BY Score DESC) AS ScoreRank,
           RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM RecentPosts
),
CombinedRanks AS (
    SELECT Id, Title, CreationDate, OwnerName, Score, CommentCount, VoteCount,
           (ScoreRank + CommentRank) AS CombinedRank
    FROM TopPosts
)
SELECT Id, Title, OwnerName, Score, CommentCount, VoteCount, CombinedRank
FROM CombinedRanks
WHERE CombinedRank <= 10
ORDER BY CombinedRank;
