WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalCloseReopenActions,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN
        PostHistory ph ON ph.UserId = u.Id AND ph.PostId IN (SELECT PostId FROM RankedPosts)
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalPosts,
        ua.TotalCloseReopenActions,
        ua.TotalBountyAmount,
        RANK() OVER (ORDER BY ua.Reputation DESC, ua.TotalPosts DESC) AS UserRank
    FROM
        UserActivity ua
    WHERE
        ua.TotalPosts > 0
)
SELECT
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    COALESCE(tu.TotalPosts, 0) AS TotalPosts,
    COALESCE(tu.TotalCloseReopenActions, 0) AS TotalCloseReopenActions,
    COALESCE(tu.TotalBountyAmount, 0) AS TotalBountyAmount,
    CASE 
        WHEN tu.TotalCloseReopenActions > 10 THEN 'Active Moderator'
        WHEN tu.Reputation > 1000 THEN 'High Reputation User'
        ELSE 'Regular User'
    END AS UserType,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Badges b 
            WHERE b.UserId = tu.UserId AND b.Class = 1
        ) THEN 'Gold Badge Holder'
        ELSE 'No Gold Badge'
    END AS BadgeStatus,
    (SELECT STRING_AGG(p.Title, '; ') 
     FROM RankedPosts p 
     WHERE p.PostRank <= 5 AND p.PostId IN (
         SELECT PostId 
         FROM Posts 
         WHERE OwnerUserId = tu.UserId
     )) AS TopPostTitles
FROM
    TopUsers tu
WHERE
    tu.UserRank <= 10
ORDER BY
    tu.UserRank;