WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12)  
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM PostHistory ph
    WHERE ph.PostId IN (SELECT PostId FROM RecursivePostHistory WHERE rn = 1)
    GROUP BY ph.PostId
),
UserContributions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.PostCount,
    a.TotalBounties,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(c.PositivePostCount, 0) AS PositivePostCount,
    cp.CloseReason,
    cp.ReopenedDate
FROM MostActiveUsers a
LEFT JOIN UserContributions c ON a.UserId = c.UserId
LEFT JOIN ClosedPosts cp ON a.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
WHERE a.PostCount > 10
ORDER BY a.TotalBounties DESC, a.PostCount DESC;