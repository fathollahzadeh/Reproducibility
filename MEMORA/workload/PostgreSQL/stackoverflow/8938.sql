WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5 Posts'
            WHEN rp.Rank BETWEEN 6 AND 15 THEN 'Top 15 Posts'
            ELSE 'Other Posts'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostCategory,
    COUNT(ps.PostId) AS PostCount,
    AVG(ps.Score) AS AvgScore,
    SUM(ps.ViewCount) AS TotalViews
FROM 
    PostScores ps
GROUP BY 
    ps.PostCategory
ORDER BY 
    CASE 
        WHEN ps.PostCategory = 'Top 5 Posts' THEN 1
        WHEN ps.PostCategory = 'Top 15 Posts' THEN 2
        ELSE 3
    END;