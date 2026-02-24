
WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT p.Tags) AS UniqueTags,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ActiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(ps.UniqueTags, 0) AS UniqueTags,
        COALESCE(ps.AvgScore, 0) AS AvgScore,
        CASE 
            WHEN COALESCE(bs.BadgeCount, 0) = 0 THEN 'No Badges'
            WHEN COALESCE(bs.GoldBadges, 0) > 0 THEN 'Gold Badge Holder'
            ELSE 'Regular User'
        END AS UserCategory,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ps.AvgScore, 0) DESC, u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeStats bs ON u.Id = bs.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR' 
),
FilteredUsers AS (
    SELECT 
        u.UserId,
        u.PostCount,
        u.BadgeCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges,
        u.UniqueTags,
        u.AvgScore,
        u.UserCategory
    FROM 
        ActiveUserStats u
    WHERE 
        u.Rank <= 10 
)
SELECT 
    f.UserId,
    f.PostCount,
    f.BadgeCount,
    f.GoldBadges,
    f.SilverBadges,
    f.BronzeBadges,
    f.UniqueTags,
    f.AvgScore,
    f.UserCategory,
    COALESCE(NULLIF(most_recent.CloseDate, '1970-01-01 00:00:00'), most_recent.ReopenDate) AS LastCloseOrReopenDate
FROM 
    FilteredUsers f
LEFT JOIN 
    (SELECT 
        p.OwnerUserId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate
     FROM 
        Posts p
     JOIN 
        PostHistory ph ON p.Id = ph.PostId
     GROUP BY 
        p.OwnerUserId) most_recent ON f.UserId = most_recent.OwnerUserId
ORDER BY 
    f.AvgScore DESC, f.PostCount DESC;
