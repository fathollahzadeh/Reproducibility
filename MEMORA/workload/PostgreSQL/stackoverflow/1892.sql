
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(b.Class, 0) AS BadgeClass,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Class = 1
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(COALESCE(ViewCount, 0)) AS AvgViews
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
HighScorers AS (
    SELECT 
        rp.OwnerUserId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ps.TotalPosts,
        ps.PositivePosts,
        ps.AvgViews
    FROM 
        RankedPosts rp
    JOIN 
        PostStats ps ON rp.OwnerUserId = ps.OwnerUserId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    u.DisplayName,
    hs.Title,
    hs.CreationDate,
    hs.Score,
    hs.TotalPosts,
    hs.PositivePosts,
    hs.AvgViews,
    CASE 
        WHEN hs.AvgViews IS NULL THEN 'No Data'
        WHEN hs.AvgViews < 100 THEN 'Low Engagement'
        WHEN hs.AvgViews BETWEEN 100 AND 500 THEN 'Moderate Engagement'
        ELSE 'High Engagement'
    END AS EngagementLevel,
    CONCAT_WS(' | ', 
               COALESCE(NULLIF(u.Location, ''), 'Location Unknown'), 
               COALESCE(NULLIF(u.WebsiteUrl, ''), 'No Website')) AS UserDetails
FROM 
    HighScorers hs
JOIN 
    Users u ON u.Id = hs.OwnerUserId
ORDER BY 
    hs.Score DESC, hs.TotalPosts DESC
LIMIT 10;
