
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        OwnerDisplayName,
        CommentCount,
        VoteCount,
        RankScore
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = tp.PostId AND ph.PostHistoryTypeId = 12) AS DeletionCount,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)) AS OwnerBadgeCount
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.CommentCount DESC;
