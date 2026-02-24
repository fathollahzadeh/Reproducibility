WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId, p.OwnerUserId
),
FilteredBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.BadgeCount, 0) AS GoldBadgeCount,
        COALESCE(rb.BadgeNames, 'None') AS GoldBadges,
        SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalPostViews
    FROM 
        Users u
    LEFT JOIN 
        FilteredBadges rb ON u.Id = rb.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, rb.BadgeCount, rb.BadgeNames
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.GoldBadgeCount,
    up.GoldBadges,
    up.TotalPostScore,
    up.TotalPostViews,
    COALESCE(phd.HistoryTypes, 'No History') AS PostHistoryTypes,
    COALESCE(phd.HistoryCount, 0) AS PostHistoryCount,
    CASE 
        WHEN up.TotalPostScore IS NULL THEN 'Score Not Available'
        WHEN up.TotalPostScore < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreStatus,
    RANK() OVER (ORDER BY up.TotalPostScore DESC) AS UserRank
FROM 
    UserMetrics up
LEFT JOIN 
    PostHistoryDetails phd ON up.UserId = phd.PostId
WHERE 
    up.GoldBadgeCount > 0 
    OR (up.TotalPostScore IS NOT NULL AND up.TotalPostScore > 100)
ORDER BY 
    UserRank
FETCH FIRST 10 ROWS ONLY;