WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostScoreStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score + COALESCE(SUM(v.BountyAmount), 0) AS TotalScore,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR' 
    GROUP BY p.Id, p.Title, p.Score
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 0 
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title,
    p.TotalScore,
    COALESCE(c.CloseCount, 0) AS CloseCount,
    c.FirstCloseDate,
    tu.UserRank
FROM UserVoteStats u
JOIN PostScoreStats p ON u.UserId = p.PostId 
LEFT JOIN ClosedPostStats c ON p.PostId = c.PostId
JOIN TopUsers tu ON u.UserId = tu.Id
WHERE p.TotalScore > 0
ORDER BY p.TotalScore DESC, u.UpVotes - u.DownVotes DESC
LIMIT 100;