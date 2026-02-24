WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankInCategory
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.ViewCount > 100
),
TopCategories AS (
    SELECT 
        pt.Name AS PostType,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    rc.PostId,
    rc.Title,
    rc.OwnerDisplayName,
    rc.CreationDate,
    rc.ViewCount,
    rc.Score,
    rc.AnswerCount,
    rc.CommentCount,
    tc.PostType,
    tc.AvgScore,
    tc.TotalViews
FROM 
    RankedPosts rc
JOIN 
    TopCategories tc ON rc.RankInCategory = 1
ORDER BY 
    tc.AvgScore DESC, rc.ViewCount DESC;