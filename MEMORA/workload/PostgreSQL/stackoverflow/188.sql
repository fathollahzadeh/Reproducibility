WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes - DownVotes AS NetVotes,
        RANK() OVER (ORDER BY UpVotes DESC) AS Rank
    FROM UserVoteStats
    WHERE PostCount > 5
),
ClosedQuestions AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.NetVotes,
    COUNT(DISTINCT cq.ClosedPostId) AS ClosedQuestionsCount,
    COALESCE(SUM(pc.CommentCount), 0) AS TotalComments
FROM TopUsers tu
LEFT JOIN ClosedQuestions cq ON tu.UserId = cq.ClosedPostId
LEFT JOIN PostComments pc ON cq.ClosedPostId = pc.PostId
GROUP BY tu.UserId, tu.DisplayName, tu.NetVotes
HAVING COUNT(DISTINCT cq.ClosedPostId) > 0
ORDER BY tu.NetVotes DESC, tu.DisplayName;
