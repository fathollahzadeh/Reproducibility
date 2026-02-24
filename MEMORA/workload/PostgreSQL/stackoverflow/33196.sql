WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.OwnerUserId,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEditRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
CombinedData AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        pp.Title AS PopularPostTitle,
        pp.ViewCount AS PopularPostViews,
        pp.CreationDate AS PopularPostDate,
        php.CloseReason,
        php.RecentEditRank
    FROM 
        UserBadges ub
    JOIN 
        Posts pp ON ub.UserId = pp.OwnerUserId
    LEFT JOIN 
        RecentPostHistory php ON pp.Id = php.PostId
    WHERE 
        ub.BadgeCount > 0 
)
SELECT 
    cd.UserId,
    cd.DisplayName,
    cd.PopularPostTitle,
    cd.PopularPostViews,
    COALESCE(cd.CloseReason, 'N/A') AS CloseReason,
    cd.RecentEditRank
FROM 
    CombinedData cd
WHERE 
    cd.RecentEditRank IS NULL OR cd.RecentEditRank = 1
ORDER BY 
    cd.PopularPostViews DESC, cd.DisplayName;