
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
UserBadgesInfo AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE
        b.Class = 1 
    GROUP BY 
        b.UserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        MAX(p.CreationDate) AS MostRecentPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.TotalPosts,
    up.TotalViews,
    up.MostRecentPostDate,
    COALESCE(uba.BadgeNames, 'No Gold Badges') AS GoldBadges,
    r.PostId,
    r.Title,
    r.ViewCount,
    p.ChangeCount AS PostHistoryChangeCount,
    CASE 
        WHEN up.TotalViews IS NULL THEN 'Anonymous User'
        ELSE CONCAT(CAST(up.UserId AS TEXT), ' - ', CAST(up.TotalViews AS TEXT))
    END AS UserViewInfo,
    ur.CommentCount,
    ur.TotalBounties,
    CASE 
        WHEN r.Rank <= 3 THEN 'Top Rank Post'
        ELSE 'Post with Lesser Views'
    END AS PostRanking
FROM 
    UserPostStats up
LEFT JOIN 
    UserBadgesInfo uba ON up.UserId = uba.UserId
JOIN 
    RankedPosts r ON up.TotalPosts > 0 AND up.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = r.PostId)
LEFT JOIN 
    RecentUserActivity ur ON up.UserId = ur.UserId
LEFT JOIN 
    PostHistoryDetails p ON r.PostId = p.PostId
WHERE 
    up.MostRecentPostDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
ORDER BY 
    up.TotalViews DESC, up.UserId;
