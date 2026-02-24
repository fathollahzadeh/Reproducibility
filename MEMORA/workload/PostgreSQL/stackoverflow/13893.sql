
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.ViewCount > 1000  
    ORDER BY p.Score DESC
    LIMIT 10
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(b.Class) AS TotalBadgeClass
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.TotalScore,
    up.AvgViewCount,
    tu.PostId,
    tu.Title AS TopPostTitle,
    tu.CreationDate AS TopPostCreationDate,
    tu.Score AS TopPostScore,
    tu.ViewCount AS TopPostViewCount,
    au.CommentCount AS UserCommentCount,
    au.TotalBadgeClass AS UserTotalBadgeClass
FROM UserPosts up
LEFT JOIN TopPosts tu ON up.DisplayName = tu.OwnerDisplayName
LEFT JOIN ActiveUsers au ON up.UserId = au.UserId
ORDER BY up.TotalScore DESC;
