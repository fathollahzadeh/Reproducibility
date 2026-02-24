
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR')
),

TopUserPosts AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        MAX(rp.ViewCount) AS MaxViews,
        MIN(rp.CreationDate) AS FirstPostDate
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
    HAVING 
        COUNT(*) >= 5
        AND SUM(rp.Score) > 10
),

UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionRN
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    tup.PostCount,
    tup.TotalScore,
    tup.MaxViews,
    tup.FirstPostDate,
    COUNT(DISTINCT ph.PostId) AS TotalPostHistoryChanges,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
    SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts,
    SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeletedPosts
FROM 
    Users u
LEFT JOIN 
    TopUserPosts tup ON u.Id = tup.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryData ph ON u.Id = ph.UserId
WHERE 
    u.Reputation > 1000 
    AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, ub.BadgeNames, tup.PostCount, tup.TotalScore, tup.MaxViews, tup.FirstPostDate
ORDER BY 
    tup.TotalScore DESC, u.DisplayName ASC
LIMIT 50 OFFSET 0;
