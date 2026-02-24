WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        tp.FavoriteCount,
        tp.OwnerDisplayName,
        COALESCE(h.PostHistoryTypeId, 0) AS LastAction,
        COALESCE(h.CreationDate, '1970-01-01') AS LastActionDate,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistory h ON tp.PostId = h.PostId
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, 
        tp.AnswerCount, tp.CommentCount, tp.FavoriteCount, tp.OwnerDisplayName, 
        h.PostHistoryTypeId, h.CreationDate
)
SELECT 
    pm.*,
    CASE 
        WHEN pm.LastAction = 10 THEN 'Closed'
        WHEN pm.LastAction = 11 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - pm.LastActionDate)) / 3600 AS HoursSinceLastAction
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;