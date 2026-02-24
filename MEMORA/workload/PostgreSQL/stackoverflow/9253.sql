
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        CASE 
            WHEN PH.PostId IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS IsClosed,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN PostHistory PH ON p.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11) 
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalComments,
        us.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM UserStatistics us
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.IsClosed
FROM TopUsers tu
JOIN PostMetrics pm ON tu.UserId = pm.OwnerUserId
WHERE tu.Rank <= 10
ORDER BY tu.Rank, pm.Score DESC;
