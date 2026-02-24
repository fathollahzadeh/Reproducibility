
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.CreationDate, u.DisplayName, pt.Name
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.CreationDate,
        rp.Tags,
        rp.RankByScore,
        rp.RankByViews,
        CASE 
            WHEN rp.RankByScore <= 5 THEN 'Top 5'
            WHEN rp.RankByScore <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS ScoreCategory,
        CASE 
            WHEN rp.RankByViews <= 5 THEN 'Top 5'
            WHEN rp.RankByViews <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS ViewCategory
    FROM 
        RankedPosts rp
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.CreationDate,
    p.Tags,
    p.ScoreCategory,
    p.ViewCategory
FROM 
    PostAnalytics p
WHERE 
    p.ScoreCategory = 'Top 5' OR p.ViewCategory = 'Top 5'
ORDER BY 
    p.RankByScore, p.RankByViews;
