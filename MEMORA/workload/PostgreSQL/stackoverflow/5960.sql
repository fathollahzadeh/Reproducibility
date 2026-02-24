
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
           COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    AND p.PostTypeId IN (1, 2)  
),
TopPosts AS (
    SELECT rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.PostRank <= 5 
),
PostDetails AS (
    SELECT tp.PostId, 
           tp.Title, 
           tp.OwnerDisplayName,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
           COUNT(c.Id) AS CommentCount
    FROM TopPosts tp
    LEFT JOIN Votes v ON tp.PostId = v.PostId
    LEFT JOIN Comments c ON tp.PostId = c.PostId
    GROUP BY tp.PostId, tp.Title, tp.OwnerDisplayName
)
SELECT pd.PostId, 
       pd.Title, 
       pd.OwnerDisplayName, 
       pd.Upvotes, 
       pd.Downvotes, 
       pd.CommentCount, 
       (pd.Upvotes - pd.Downvotes) AS ScoreBalance
FROM PostDetails pd
ORDER BY ScoreBalance DESC;
