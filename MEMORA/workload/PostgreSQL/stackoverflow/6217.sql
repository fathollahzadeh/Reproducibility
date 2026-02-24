WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
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
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, pt.Name
),
TopScoringPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
),
TopViewingPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByViews <= 10
)
SELECT 
    t1.Title AS TopScoringPostTitle,
    t1.OwnerDisplayName AS ScoringOwner,
    t1.Score AS TopScore,
    t1.ViewCount AS TopScoreViews,
    t2.Title AS TopViewingPostTitle,
    t2.OwnerDisplayName AS ViewingOwner,
    t2.Score AS TopViewScore,
    t2.ViewCount AS TopViewCount
FROM 
    TopScoringPosts t1
FULL OUTER JOIN 
    TopViewingPosts t2 ON t1.PostId = t2.PostId
ORDER BY 
    COALESCE(t1.Score, 0) DESC, COALESCE(t2.ViewCount, 0) DESC;
