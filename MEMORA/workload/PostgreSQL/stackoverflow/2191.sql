WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
        AND p.PostTypeId = 1
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.Reputation, u.DisplayName
),
TopBadges AS (
    SELECT
        b.UserId,
        ARRAY_AGG(b.Name) AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM
        Badges b
    GROUP BY
        b.UserId
)
SELECT
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.AcceptedAnswers,
    rp.Title,
    rp.ViewCount,
    tb.BadgeNames,
    CASE
        WHEN us.Reputation > 1000 THEN 'High Reputation'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM
    UserStats us
    JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
    LEFT JOIN TopBadges tb ON us.UserId = tb.UserId
WHERE
    rp.PostRank = 1
ORDER BY
    us.Reputation DESC, rp.ViewCount DESC
LIMIT 10;