
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COUNT(DISTINCT ph.PostId) AS HistoryRecordCount,
        RANK() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) 
                     - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, UpVoteCount, DownVoteCount, CommentCount, HistoryRecordCount,
        RANK() OVER (ORDER BY HistoryRecordCount DESC) AS TopRank
    FROM UserActivity
    WHERE ReputationRank <= 50
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS TotalCloseVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= '2022-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate
)
SELECT 
    tu.DisplayName AS TopUser,
    ts.Title AS PostTitle,
    ts.TotalBounty,
    ts.TotalComments,
    ts.TotalCloseVotes,
    CASE 
        WHEN ts.TotalCloseVotes > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CONCAT('User ', COALESCE(uc.UserId, 0), ' has ', 
    COALESCE(uc.UpVoteCount, 0), ' upvotes and ', 
    COALESCE(uc.DownVoteCount, 0), ' downvotes.') AS UserVoteSummary
FROM TopUsers tu
JOIN PostStats ts ON tu.UserId = ts.PostId
LEFT JOIN UserActivity uc ON uc.UserId = tu.UserId
WHERE tu.TopRank <= 10
ORDER BY ts.TotalBounty DESC, ts.TotalComments DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
