
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        Questions,
        Answers,
        Wikis,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation
    FROM UserReputation
    WHERE Reputation > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
FinalResults AS (
    SELECT 
        tu.UserId,
        tu.Reputation,
        tu.PostCount,
        tu.Questions,
        tu.Answers,
        tu.Wikis,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        tu.RankByReputation
    FROM TopUsers tu
    LEFT JOIN UserBadges ub ON tu.UserId = ub.UserId
)
SELECT 
    fr.UserId,
    fr.Reputation,
    fr.PostCount,
    fr.Questions,
    fr.Answers,
    fr.Wikis,
    fr.BadgeCount,
    fr.GoldBadges,
    fr.SilverBadges,
    fr.BronzeBadges
FROM FinalResults fr
WHERE fr.RankByReputation <= 10
ORDER BY fr.Reputation DESC;
