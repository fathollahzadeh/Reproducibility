WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CreationDate,
        PostType,
        Author
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        tp.PostType,
        tp.Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.ViewCount, tp.Score, tp.PostType, tp.Author
),
PostMetrics AS (
    SELECT 
        pd.*,
        CASE 
            WHEN pd.Score > 100 THEN 'High Engagement'
            WHEN pd.Score BETWEEN 50 AND 100 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        PostDetails pd
)
SELECT 
    PM.Title,
    PM.ViewCount,
    PM.Score,
    PM.CommentCount,
    PM.VoteCount,
    PM.PostType,
    PM.Author,
    PM.EngagementLevel
FROM 
    PostMetrics PM
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC;
