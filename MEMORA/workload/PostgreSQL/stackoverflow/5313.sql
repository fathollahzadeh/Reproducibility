
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        UpvotedPosts, 
        DownvotedPosts, 
        CommentCount,
        TotalBounties,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM UserActivity
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.PostCount,
    t.UpvotedPosts,
    t.DownvotedPosts,
    t.CommentCount,
    t.TotalBounties,
    RANK() OVER (ORDER BY t.TotalBounties DESC) AS BountyRank
FROM TopUsers t
WHERE t.Rank <= 10
ORDER BY t.PostCount DESC;
