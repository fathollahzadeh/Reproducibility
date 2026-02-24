
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        LEAD(p.Score) OVER (ORDER BY p.CreationDate) AS NextPostScore,
        SUM(p.Score) OVER () AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
),
UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        (CASE 
            WHEN u.Reputation IS NULL THEN 'No Reputation' 
            WHEN u.Reputation < 100 THEN 'Low Reputation' 
            ELSE 'High Reputation' END) AS ReputationCategory
    FROM 
        Users u
    WHERE 
        u.CreationDate < DATE '2024-10-01'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankByUser,
        uh.Reputation,
        uh.ReputationCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputationHistory uh ON rp.PostId = uh.UserId
    WHERE 
        rp.RankByUser = 1 AND rp.ViewCount > 50
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViews,
        SUM(Score) AS TotalScore,
        MAX(Score) AS MaxScore
    FROM 
        FilteredPosts
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    p.TotalPosts,
    p.AverageViews,
    p.TotalScore,
    p.MaxScore,
    (CASE 
        WHEN fp.Score >= p.MaxScore * 0.8 THEN 'Top Performer'
        ELSE 'Needs Improvement' END) AS PerformanceStatus,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount
FROM 
    FilteredPosts fp,
    PostStats p
WHERE
    fp.ReputationCategory = 'High Reputation' 
    OR (fp.ReputationCategory = 'Low Reputation' AND fp.Score >= (SELECT AVG(Score) FROM FilteredPosts WHERE ReputationCategory = 'Low Reputation'))
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, fp.Score, 
    p.TotalPosts, p.AverageViews, p.TotalScore, p.MaxScore, 
    fp.ReputationCategory
ORDER BY 
    fp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
