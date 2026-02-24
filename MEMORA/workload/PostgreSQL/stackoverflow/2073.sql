
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
    WHERE PostCount > 5
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBounty,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    ARRAY_AGG(DISTINCT p.Title) AS PostTitles,
    COALESCE(NullHandling.NullCount, 0) AS NullPostCount,
    SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
FROM TopUsers tu
LEFT JOIN Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY PostId
) c ON p.Id = c.PostId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS NullCount
    FROM Posts
    WHERE Title IS NULL
    GROUP BY UserId
) NullHandling ON tu.UserId = NullHandling.UserId
GROUP BY tu.UserId, tu.DisplayName, tu.Reputation, tu.TotalBounty, c.CommentCount, NullHandling.NullCount
ORDER BY tu.Reputation DESC
LIMIT 10;
