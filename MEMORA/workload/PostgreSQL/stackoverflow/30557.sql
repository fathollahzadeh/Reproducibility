
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 100 
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalBounty,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserActivity
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn,
        ph.UserId
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') 
    AND ph.PostHistoryTypeId IN (10, 11, 12, 13) 
)
SELECT 
    u.DisplayName AS TopUser,
    u.Reputation AS UserReputation,
    COALESCE(u.PostCount, 0) AS TotalPosts,
    COALESCE(u.CommentCount, 0) AS TotalComments,
    COALESCE(u.TotalBounty, 0) AS TotalBounty,
    pp.Title AS RecentlyModifiedPost,
    pp.CreationDate AS ModificationDate,
    pp.UserDisplayName AS Modifier,
    pp.Comment AS ModificationComment
FROM TopUsers u
LEFT JOIN RecentPostHistory pp ON u.UserId = pp.UserId
WHERE u.ReputationRank <= 10 
ORDER BY u.Reputation DESC, u.PostCount DESC;
