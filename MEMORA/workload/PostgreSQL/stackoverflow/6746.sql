
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostTypeId = 1 AND rp.Rank <= 10
),
TopAnswers AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostTypeId = 2 AND rp.Rank <= 10
)
SELECT 
    'Top Questions' AS PostCategory,
    Title,
    ViewCount,
    Score,
    OwnerDisplayName
FROM 
    TopQuestions
UNION ALL
SELECT 
    'Top Answers' AS PostCategory,
    Title,
    ViewCount,
    Score,
    OwnerDisplayName
FROM 
    TopAnswers
ORDER BY 
    PostCategory, 
    ViewCount DESC;
