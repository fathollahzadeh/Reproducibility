WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        U.LastAccessDate,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.LastAccessDate
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.ActivePostCount,
    au.TotalViews,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    CASE 
        WHEN au.TotalViews > 1000 THEN 'High Activity'
        WHEN au.TotalViews BETWEEN 500 AND 1000 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    STRING_AGG(DISTINCT ht.Name, ', ') AS HistoryTypes
FROM 
    ActiveUsers au
LEFT JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistory ph ON rp.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
WHERE 
    rp.Rank <= 3
GROUP BY 
    au.DisplayName, au.Reputation, au.ActivePostCount, au.TotalViews, rp.Title, rp.Score, rp.CommentCount
ORDER BY 
    au.Reputation DESC, au.TotalViews DESC;