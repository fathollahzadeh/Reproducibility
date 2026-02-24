
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Owner,
        rp.CommentCount,
        CASE 
            WHEN rp.RankByViews <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS ViewRank
    FROM 
        RankedPosts rp
)
SELECT 
    ps.Owner,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.ViewCount) AS TotalViews,
    AVG(ps.CommentCount) AS AverageComments,
    MAX(ps.ViewCount) AS MaxViews
FROM 
    PostStatistics ps
WHERE 
    ps.ViewRank = 'Top 5'
GROUP BY 
    ps.Owner
ORDER BY 
    TotalViews DESC
LIMIT 10;
