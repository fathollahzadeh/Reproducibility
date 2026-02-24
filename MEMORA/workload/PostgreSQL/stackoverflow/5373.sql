
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.ViewCount DESC) AS RankViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId 
    LEFT JOIN 
        Tags t ON t.Id = pl.RelatedPostId
    WHERE 
        p.PostTypeId = 1 AND p.ClosedDate IS NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
AggregatedData AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        AnswerCount,
        RankScore,
        RankViews,
        Tags,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN RankScore <= 10 THEN 'Top Score'
            WHEN RankViews <= 10 THEN 'Top Views'
            ELSE 'Others' END ORDER BY RankScore, RankViews) AS RowNum
    FROM 
        RankedPosts
)
SELECT 
    AD.PostId,
    AD.Title,
    AD.CreationDate,
    AD.Score,
    AD.ViewCount,
    AD.CommentCount,
    AD.AnswerCount,
    AD.Tags
FROM 
    AggregatedData AD
WHERE 
    AD.RowNum <= 10
ORDER BY 
    AD.RankScore, AD.RankViews;
