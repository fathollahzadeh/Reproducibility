
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pc.PostCount, 0) AS PostCount,
        COALESCE(pc.TotalViews, 0) AS TotalViews,
        COALESCE(pc.AvgScore, 0) AS AvgScore,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN PostMetrics pc ON u.Id = pc.OwnerUserId
    LEFT JOIN UserBadgeCounts bc ON u.Id = bc.UserId
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        AvgScore,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalViews DESC, AvgScore DESC) AS Rank
    FROM UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    AvgScore,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Rank
FROM RankedUsers
WHERE Rank <= 10
ORDER BY Rank;
