WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           u.DisplayName AS OwnerDisplayName,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           p.AnswerCount,
           p.CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT PostId, Title, OwnerDisplayName, Score, ViewCount, AnswerCount, CommentCount
    FROM RankedPosts
    WHERE Rank <= 10
),
PostVoteStats AS (
    SELECT PostId, 
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY PostId
)
SELECT tp.Title,
       tp.OwnerDisplayName,
       tp.Score,
       tp.ViewCount,
       tp.AnswerCount,
       tp.CommentCount,
       COALESCE(pvs.UpVotes, 0) AS UpVotes,
       COALESCE(pvs.DownVotes, 0) AS DownVotes
FROM TopPosts tp
LEFT JOIN PostVoteStats pvs ON tp.PostId = pvs.PostId
ORDER BY tp.Score DESC, tp.ViewCount DESC;