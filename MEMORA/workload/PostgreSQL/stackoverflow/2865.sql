WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 AND 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS ClosedQuestions,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.PostId END) AS DeletedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.TotalQuestions,
    us.ClosedQuestions,
    us.DeletedQuestions,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    rp.Score AS LatestPostScore,
    rp.ViewCount AS LatestPostViews
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.TotalQuestions > 0 
ORDER BY 
    us.TotalQuestions DESC, 
    us.ClosedQuestions ASC
LIMIT 10;