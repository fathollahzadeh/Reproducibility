WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.OwnerName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostScores AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CreationDate,
        tp.Score,
        tp.OwnerName,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        CASE 
            WHEN tp.Score >= 0 THEN 'Positive'
            WHEN tp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CreationDate,
    ps.Score,
    ps.OwnerName,
    ps.TotalComments,
    ps.ScoreCategory,
    (SELECT STRING_AGG(pt.Name, ', ')
     FROM PostHistory ph
     JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
     WHERE ph.PostId = ps.PostId
     AND ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month') AS RecentHistory
FROM 
    PostScores ps
WHERE 
    ps.TotalComments > 5
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;