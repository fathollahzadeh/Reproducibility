
WITH UserReputation AS (
    SELECT Id AS UserId, Reputation, CreationDate
    FROM Users
    WHERE Reputation > 1000
), 
ActivePosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
    FROM Posts p
    INNER JOIN UserReputation ur ON p.OwnerUserId = ur.UserId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND p.PostTypeId = 1 
), 
TopTaggedPosts AS (
    SELECT ap.PostId, SUM(t.Count) AS TagCount
    FROM ActivePosts ap
    JOIN Tags t ON t.WikiPostId = ap.PostId
    GROUP BY ap.PostId
    ORDER BY TagCount DESC
    LIMIT 10
), 
PostComments AS (
    SELECT c.PostId, COUNT(c.Id) AS CommentCount
    FROM Comments c
    JOIN TopTaggedPosts ttp ON c.PostId = ttp.PostId
    GROUP BY c.PostId
), 
FinalResults AS (
    SELECT ap.PostId, ap.Title, ap.CreationDate, ap.Score, ap.ViewCount, pc.CommentCount, ap.OwnerUserId
    FROM ActivePosts ap
    LEFT JOIN PostComments pc ON ap.PostId = pc.PostId
)
SELECT 
    fr.PostId, 
    fr.Title, 
    fr.CreationDate AS PostCreationDate,
    fr.Score, 
    fr.ViewCount, 
    COALESCE(fr.CommentCount, 0) AS TotalComments,
    ur.Reputation AS OwnerReputation
FROM FinalResults fr
JOIN UserReputation ur ON fr.OwnerUserId = ur.UserId
ORDER BY fr.ViewCount DESC, fr.Score DESC
LIMIT 20;
