WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           u.DisplayName AS Owner, 
           p.ViewCount, 
           p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score IS NOT NULL
), 
TopScores AS (
    SELECT Owner, 
           MAX(Score) AS MaxScore,
           COUNT(PostId) AS PostCount
    FROM RankedPosts
    WHERE Rank <= 3
    GROUP BY Owner
), 
RecentActivity AS (
    SELECT p.OwnerDisplayName,
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.LastActivityDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY p.OwnerDisplayName
) 
SELECT t.Owner, 
       t.MaxScore, 
       t.PostCount, 
       ra.CommentCount, 
       ra.VoteCount
FROM TopScores t
JOIN RecentActivity ra ON t.Owner = ra.OwnerDisplayName
ORDER BY t.MaxScore DESC, t.PostCount DESC
LIMIT 10;