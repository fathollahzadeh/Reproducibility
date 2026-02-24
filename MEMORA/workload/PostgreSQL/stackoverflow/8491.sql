
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           PFT.Name AS PostType, 
           ROW_NUMBER() OVER (PARTITION BY PFT.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN PostTypes PFT ON p.PostTypeId = PFT.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
TopRanked AS (
    SELECT PostId, Title, CreationDate, Score, ViewCount, PostType
    FROM RankedPosts
    WHERE Rank <= 10
),
UserEngagement AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT v.Id) AS VoteCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostComments AS (
    SELECT p.Id AS PostId, 
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
)
SELECT TR.PostId, TR.Title, TR.CreationDate, TR.Score, TR.ViewCount, TR.PostType, 
       UE.UserId, UE.DisplayName, UE.VoteCount, UE.UpVotes, UE.DownVotes, 
       PC.CommentCount
FROM TopRanked TR
JOIN UserEngagement UE ON TR.PostId = UE.UserId
JOIN PostComments PC ON TR.PostId = PC.PostId
ORDER BY TR.Score DESC, TR.ViewCount DESC;
