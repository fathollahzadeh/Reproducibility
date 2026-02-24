WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.ViewCount DESC) AS RankView
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
), 
TopScoringPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
),
TopViewedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankView <= 10
)
SELECT 
    ts.PostId,
    ts.Title,
    ts.Score,
    ts.ViewCount,
    ts.OwnerDisplayName,
    ts.CommentCount,
    'Top Scoring' AS PostCategory
FROM 
    TopScoringPosts ts

UNION ALL

SELECT 
    tv.PostId,
    tv.Title,
    tv.Score,
    tv.ViewCount,
    tv.OwnerDisplayName,
    tv.CommentCount,
    'Top Viewed' AS PostCategory
FROM 
    TopViewedPosts tv

ORDER BY 
    PostCategory, Score DESC;