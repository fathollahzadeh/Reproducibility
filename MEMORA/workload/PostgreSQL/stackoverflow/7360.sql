WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        MAX(u.Reputation) AS Reputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.TotalScore,
        us.Reputation,
        COALESCE(bs.BadgeCount, 0) AS BadgeCount,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
    FROM UserStats us
    LEFT JOIN BadgeStats bs ON us.UserId = bs.UserId
),
FinalStats AS (
    SELECT 
        UserId,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        Reputation,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM CombinedStats
)

SELECT 
    UserId,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    Reputation,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    ScoreRank
FROM FinalStats
WHERE ScoreRank <= 10
ORDER BY TotalScore DESC, Reputation DESC;
