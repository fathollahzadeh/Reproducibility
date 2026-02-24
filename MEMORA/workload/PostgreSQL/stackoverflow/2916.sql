WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(v.BountyAmount) AS TotalBountiesEarned
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpvotedPosts,
        DownvotedPosts,
        TotalBountiesEarned,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
TopUsersPosts AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM TopUsers tu
    INNER JOIN Posts p ON tu.UserId = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE tu.Rank <= 10
)
SELECT 
    t.DisplayName,
    COUNT(t.Title) AS TotalPosts,
    SUM(CASE WHEN t.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
    SUM(t.CommentCount) AS TotalComments,
    AVG(u.Reputation) AS AvgReputation
FROM TopUsersPosts t
JOIN Users u ON t.UserId = u.Id
GROUP BY t.DisplayName
HAVING SUM(t.CommentCount) > 5
ORDER BY TotalPosts DESC
LIMIT 5;
