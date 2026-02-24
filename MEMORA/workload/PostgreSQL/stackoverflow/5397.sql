
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.PostTypeId,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        pt.Name AS PostType,
        COALESCE(u.Reputation, 0) AS OwnerReputation
    FROM RankedPosts rp
    JOIN PostTypes pt ON rp.PostTypeId = pt.Id
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE rp.Rank <= 5
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY PostId
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.PostType,
    tp.OwnerReputation,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes
FROM TopPosts tp
LEFT JOIN PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN PostVotes pv ON tp.PostId = pv.PostId
ORDER BY tp.Score DESC, tp.ViewCount DESC;
