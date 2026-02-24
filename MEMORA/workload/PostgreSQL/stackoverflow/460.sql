WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
CommentStats AS (
    SELECT 
        PostId, 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(cs.TotalComments, 0) AS TotalComments,
        COALESCE(cs.AverageCommentScore, 0) AS AverageCommentScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentStats cs ON rp.PostId = cs.PostId
    WHERE 
        rp.RankScore = 1
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.Score > 100 THEN 'Hot'
        WHEN tp.Score > 50 THEN 'Trending'
        ELSE 'New'
    END AS PostStatus,
    CASE 
        WHEN tp.Score IS NULL THEN 'No Score'
        ELSE 'Scored'
    END AS ScoreStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.TotalComments DESC
LIMIT 10;