
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
        AND p.PostTypeId = 1 
),
TopScoringPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostStatistics AS (
    SELECT 
        t.DisplayName AS OwnerDisplayName,
        COUNT(tp.PostId) AS TopPostCount,
        SUM(tp.ViewCount) AS TotalViews,
        AVG(tp.Score) AS AverageScore,
        MAX(tp.CreationDate) AS LastPostDate
    FROM 
        TopScoringPosts tp
    JOIN 
        Users t ON tp.OwnerDisplayName = t.DisplayName
    GROUP BY 
        t.DisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TopPostCount,
    ps.TotalViews,
    ps.AverageScore,
    ps.LastPostDate,
    b.Class,
    COUNT(b.Id) AS BadgeCount
FROM 
    PostStatistics ps
LEFT JOIN 
    Badges b ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
GROUP BY 
    ps.OwnerDisplayName, ps.TopPostCount, ps.TotalViews, ps.AverageScore, ps.LastPostDate, b.Class
ORDER BY 
    ps.TotalViews DESC
LIMIT 10;
