
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.OwnerName, 
        ps.Score, 
        ps.ViewCount, 
        ps.Rank 
    FROM 
        PostStats ps
    WHERE 
        ps.Rank <= 10 
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.Score,
    tp.ViewCount,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(ph2.CreationDate) 
        FROM PostHistory ph2
        WHERE ph2.PostId = tp.PostId AND ph2.PostHistoryTypeId IN (4, 5)
    )
WHERE 
    tp.Score > 10 
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
