
WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY u.Id, u.DisplayName
), 

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
), 

UserRankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.CommentCount,
        ps.CloseCount,
        ps.ReopenCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ps.Score DESC, ps.CreationDate DESC) AS PostRank
    FROM PostStats ps
    JOIN Posts p ON ps.PostId = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
), 

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ua.TotalViews,
        ua.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ua.TotalViews DESC) AS ViewRank
    FROM RecursiveUserActivity ua
    JOIN Users u ON ua.UserId = u.Id
)
SELECT 
    tu.DisplayName AS UserName,
    tu.TotalViews,
    tu.TotalBounty,
    up.Title AS PostTitle,
    up.CreationDate AS PostDate,
    up.Score AS PostScore,
    up.CommentCount,
    up.CloseCount,
    up.ReopenCount
FROM TopUsers tu
LEFT JOIN UserRankedPosts up ON tu.UserId = up.PostId 
WHERE tu.ViewRank <= 10 AND up.PostRank <= 5
ORDER BY tu.TotalViews DESC, up.Score DESC;
