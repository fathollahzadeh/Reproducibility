
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
), TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CommentCount,
        UpVotes,
        DownVotes,
        CloseVotes,
        RecentRank
    FROM 
        PostStats
    WHERE 
        RecentRank <= 100
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CloseVotes,
    COALESCE(SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS EditHistoryCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
GROUP BY 
    tp.Title, tp.ViewCount, tp.Score, tp.CommentCount, tp.UpVotes, tp.DownVotes, tp.CloseVotes
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
