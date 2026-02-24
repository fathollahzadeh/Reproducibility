WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(b.Class) AS AverageBadgeClass
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON c.PostId = tp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = tp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.Score, tp.ViewCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.AverageBadgeClass,
    CASE 
        WHEN ps.Score >= 100 THEN 'High Scorer'
        WHEN ps.Score BETWEEN 50 AND 99 THEN 'Medium Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, 
    ps.CommentCount DESC;