WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AverageAnswers,
        AVG(p.CommentCount) AS AverageComments
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pb.PostCount, 0) AS PostCount,
        COALESCE(pb.TotalScore, 0) AS TotalScore,
        COALESCE(pb.TotalViews, 0) AS TotalViews,
        COALESCE(pb.AverageAnswers, 0) AS AverageAnswers,
        COALESCE(pb.AverageComments, 0) AS AverageComments,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN PostStats pb ON u.Id = pb.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    AverageAnswers,
    AverageComments,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM CombinedStats
ORDER BY TotalScore DESC, PostCount DESC
LIMIT 10;