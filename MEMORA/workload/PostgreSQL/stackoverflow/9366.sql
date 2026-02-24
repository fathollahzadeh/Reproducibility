WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate, 
        Score, 
        ViewCount 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostsWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.Score, tp.ViewCount
),
FinalResults AS (
    SELECT 
        pwc.*,
        CASE 
            WHEN pwc.ViewCount > 1000 THEN 'High Traffic'
            WHEN pwc.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Traffic'
            ELSE 'Low Traffic'
        END AS TrafficCategory
    FROM 
        PostsWithComments pwc
)
SELECT 
    PostId, 
    Title, 
    OwnerDisplayName, 
    CreationDate, 
    Score, 
    ViewCount, 
    CommentCount,
    TrafficCategory
FROM 
    FinalResults
ORDER BY 
    Score DESC, 
    CreationDate DESC;