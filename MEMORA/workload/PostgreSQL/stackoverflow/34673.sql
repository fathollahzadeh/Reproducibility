WITH RECURSIVE UserEngagement AS (
    SELECT 
        UserId, 
        COUNT(DISTINCT PostId) AS PostCount,
        COUNT(DISTINCT CASE WHEN VoteTypeId = 2 THEN PostId END) AS Upvotes,
        COUNT(DISTINCT CASE WHEN VoteTypeId = 3 THEN PostId END) AS Downvotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Score
    FROM Votes v
    JOIN Posts p ON v.PostId = p.Id
    GROUP BY UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ue.PostCount,
        ue.Upvotes,
        ue.Downvotes,
        ue.Score,
        RANK() OVER (ORDER BY ue.Score DESC) AS ScoreRank
    FROM Users u
    JOIN UserEngagement ue ON u.Id = ue.UserId
    WHERE ue.Score > 0
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN p.Id IN (SELECT DISTINCT PostId FROM Votes WHERE VoteTypeId = 2) THEN v.UserId END) AS UpvotedByCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastChange
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Score,
    tu.PostCount,
    ap.Title AS ActivePostTitle,
    ap.CommentCount,
    ap.UpvotedByCount,
    ph.LastChange
FROM TopUsers tu
JOIN ActivePosts ap ON tu.UserId = ap.OwnerUserId
LEFT JOIN PostHistorySummary ph ON ap.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
WHERE tu.ScoreRank <= 10
ORDER BY tu.Score DESC, ap.CreationDate DESC;