WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), BadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
), ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        BadgeSummary bs ON u.Id = bs.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, bs.BadgeCount
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalViews,
    us.TotalScore,
    rp.PostTitle,
    cp.CloseReason,
    cp.CloseDate
FROM 
    UserStats us
LEFT JOIN 
    (SELECT PostId, Title AS PostTitle FROM RankedPosts WHERE PostRank = 1) rp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    ClosedPosts cp ON cp.Id = rp.PostId
WHERE 
    us.BadgeCount > 0
ORDER BY 
    us.TotalScore DESC, us.TotalViews DESC;