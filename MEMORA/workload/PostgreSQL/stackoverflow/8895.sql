WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
TopScorePosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5
),
TopViewPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, CommentCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 5
),
CombinedTopPosts AS (
    SELECT 
        t.Title, t.CreationDate, t.Score, t.ViewCount, t.AnswerCount, t.CommentCount, t.OwnerDisplayName, 'Top Score' AS RankType
    FROM 
        TopScorePosts t
    UNION ALL
    SELECT 
        t.Title, t.CreationDate, t.Score, t.ViewCount, t.AnswerCount, t.CommentCount, t.OwnerDisplayName, 'Top Views' AS RankType
    FROM 
        TopViewPosts t
)
SELECT 
    RankType,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    OwnerDisplayName
FROM 
    CombinedTopPosts
ORDER BY 
    RankType, Score DESC, ViewCount DESC;
