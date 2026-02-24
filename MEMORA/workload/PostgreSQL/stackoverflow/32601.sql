
WITH RECURSIVE UserBadges AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
),
AveragePosts AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore
    FROM
        Posts P
    WHERE
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY
        P.OwnerUserId
),
ActiveUsers AS (
    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(AP.PostCount, 0) AS PostCount,
        COALESCE(AP.AverageScore, 0) AS AverageScore
    FROM
        Users U
    LEFT JOIN
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN
        AveragePosts AP ON U.Id = AP.OwnerUserId
    WHERE
        U.Reputation > 1000
)
SELECT
    AU.DisplayName,
    AU.Reputation,
    AU.BadgeCount,
    AU.PostCount,
    AU.AverageScore,
    CASE
        WHEN AU.BadgeCount > 10 THEN 'Highly Decorated'
        WHEN AU.BadgeCount BETWEEN 5 AND 10 THEN 'Moderately Decorated'
        ELSE 'Needs More Contribution'
    END AS BadgeStatus,
    P.Title AS RecentPostTitle,
    P.Score AS RecentPostScore,
    P.LastActivityDate
FROM
    ActiveUsers AU
LEFT JOIN
    Posts P ON AU.Id = P.OwnerUserId
WHERE
    P.CreationDate = (
        SELECT MAX(P2.CreationDate)
        FROM Posts P2
        WHERE P2.OwnerUserId = AU.Id
    )
ORDER BY
    AU.Reputation DESC,
    AU.BadgeCount DESC,
    AU.AverageScore DESC
LIMIT 10;
