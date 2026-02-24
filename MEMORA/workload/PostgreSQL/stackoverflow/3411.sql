WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
PostStatistics AS (
    SELECT 
        pp.OwnerName,
        COUNT(*) AS TotalPosts,
        SUM(pp.Score) AS TotalScore,
        AVG(pp.ViewCount) AS AverageViews
    FROM 
        RankedPosts pp
    WHERE 
        pp.Rank <= 3
    GROUP BY 
        pp.OwnerName
)
SELECT 
    ps.OwnerName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AverageViews,
    CASE 
        WHEN ps.TotalScore > 100 THEN 'High Score'
        WHEN ps.TotalScore BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    (SELECT COUNT(DISTINCT b.Id) 
     FROM Badges b 
     JOIN Users u ON b.UserId = u.Id 
     WHERE u.DisplayName = ps.OwnerName) AS BadgeCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.TotalScore DESC
LIMIT 10;