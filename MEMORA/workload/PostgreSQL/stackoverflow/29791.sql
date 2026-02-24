WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Questions,
        Answers,
        TagWikis,
        PositiveScorePosts,
        NegativeScorePosts,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM
        UserReputation
),
UserBadges AS (
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
UserPostHistory AS (
    SELECT
        p.OwnerUserId,
        COUNT(ph.Id) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId BETWEEN 4 AND 6 THEN 1 ELSE 0 END) AS TotalEdits,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        p.OwnerUserId
)
SELECT
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.Questions,
    tu.Answers,
    tu.TagWikis,
    tu.PositiveScorePosts,
    tu.NegativeScorePosts,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    uph.EditCount,
    uph.TotalEdits,
    uph.LastEditDate
FROM
    TopUsers tu
LEFT JOIN
    UserBadges ub ON tu.UserId = ub.UserId
LEFT JOIN
    UserPostHistory uph ON tu.UserId = uph.OwnerUserId
WHERE
    tu.ReputationRank <= 10
ORDER BY
    tu.Reputation DESC;
