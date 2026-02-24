
WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalUpvotes,
        TotalDownvotes,
        AcceptedAnswers,
        TotalPosts,
        RANK() OVER (ORDER BY TotalUpvotes - TotalDownvotes DESC) AS UserRank
    FROM UserScore
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), '1970-01-01') AS ClosedDate,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS RelatedLinks
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    tu.AcceptedAnswers,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.ClosedDate,
    ps.RelatedLinks
FROM TopUsers tu
JOIN PostStatistics ps ON ps.ViewCount > 50 AND (tu.AcceptedAnswers > 0 OR ps.CommentCount > 10)
WHERE tu.UserRank <= 10
ORDER BY (tu.TotalUpvotes - tu.TotalDownvotes) DESC, ps.ViewCount DESC;
