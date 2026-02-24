
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
TopPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
PostJoin AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        tr.Reputation AS UserReputation
    FROM TopPosts tp
    JOIN UserReputation tr ON tr.UserId = tp.AcceptedAnswerId
    WHERE tp.PostRank <= 5
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.OwnerDisplayName,
    p.UserReputation,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM PostJoin p
LEFT JOIN PostComments pc ON p.PostId = pc.PostId
ORDER BY p.Score DESC, p.ViewCount DESC;
