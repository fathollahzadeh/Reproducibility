
WITH ActiveUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           SUM(v.BountyAmount) AS TotalBounty,
           COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.LastAccessDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostStats AS (
    SELECT p.Id AS PostId, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerId,
           COUNT(DISTINCT c.Id) AS TotalComments,
           SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
           MAX(p.CreationDate) AS LastActivity
    FROM Posts p 
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerId
),
TopUsers AS (
    SELECT au.DisplayName, au.Reputation, au.TotalBounty, au.TotalPosts, 
           RANK() OVER (ORDER BY au.Reputation DESC) AS UserRank
    FROM ActiveUsers au
    WHERE au.TotalPosts > 5
),
TopPosts AS (
    SELECT ps.PostId, ps.Title, ps.Score, ps.ViewCount, ps.TotalComments, 
           RANK() OVER (ORDER BY ps.ViewCount DESC) AS PostRank
    FROM PostStats ps
    WHERE ps.ClosedCount = 0
)
SELECT tu.DisplayName, tu.Reputation, tu.TotalBounty, tp.Title, tp.Score, tp.ViewCount, tp.TotalComments
FROM TopUsers tu
JOIN TopPosts tp ON tu.TotalPosts > 10
WHERE tu.UserRank <= 10 AND tp.PostRank <= 20
ORDER BY tu.Reputation DESC, tp.ViewCount DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
