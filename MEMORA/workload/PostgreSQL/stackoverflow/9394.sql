
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)), 0)) AS AvgActivityDuration
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS PostHistoryCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeletionVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.Questions,
    us.Answers,
    us.TotalViews,
    us.TotalScore,
    us.AvgActivityDuration,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(phs.PostHistoryCount, 0) AS PostHistoryCount,
    COALESCE(phs.CloseVotes, 0) AS CloseVotes,
    COALESCE(phs.ReopenVotes, 0) AS ReopenVotes,
    COALESCE(phs.DeletionVotes, 0) AS DeletionVotes
FROM 
    UserStats us
LEFT JOIN 
    BadgeStats bs ON us.UserId = bs.UserId
LEFT JOIN 
    PostHistoryStats phs ON us.UserId = phs.UserId
ORDER BY 
    us.TotalScore DESC, us.PostCount DESC
FETCH FIRST 100 ROWS ONLY;
