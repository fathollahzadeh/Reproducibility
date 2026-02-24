
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unrated'
            WHEN u.Reputation < 100 THEN 'Novice'
            WHEN u.Reputation < 500 THEN 'Intermediate'
            WHEN u.Reputation < 1000 THEN 'Experienced'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(p.Score) AS AverageScore,
        p.CreationDate,
        DENSE_RANK() OVER (ORDER BY AVG(p.Score) DESC) AS ScoreRank
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id 
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.CreationDate
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.Comment
),
CombinedData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        us.ReputationLevel,
        ps.CommentCount,
        ps.VoteCount,
        ps.AverageScore,
        cpr.CloseReason,
        cpr.CloseCount
    FROM Posts p
    JOIN UserReputation us ON p.OwnerUserId = us.UserId
    JOIN PostStatistics ps ON p.Id = ps.PostId
    LEFT JOIN ClosedPostReasons cpr ON p.Id = cpr.PostId
    WHERE 
        (ps.CommentCount > 10 OR ps.VoteCount > 5)
        AND (cpr.CloseCount IS NULL OR cpr.CloseCount < 3)
)

SELECT 
    PostId,
    Title,
    ReputationLevel,
    CommentCount,
    VoteCount,
    AverageScore,
    COALESCE(CloseReason, 'No Close Reason') AS CloseReason,
    COALESCE(CloseCount, 0) AS CloseCount,
    CASE 
        WHEN AverageScore IS NULL THEN 'Score Not Available'
        ELSE CASE 
            WHEN AverageScore > 10 THEN 'High Engagement'
            ELSE 'Low Engagement'
        END 
    END AS EngagementLevel
FROM CombinedData
ORDER BY AverageScore DESC, VoteCount DESC
LIMIT 100;
