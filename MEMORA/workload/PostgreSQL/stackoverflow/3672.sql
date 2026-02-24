
WITH UserReputation AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.Comment 
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE pht.Name = 'Post Closed'
),
CombinedResults AS (
    SELECT 
        ur.DisplayName, 
        ur.ReputationLevel,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.AnswerCount,
        ps.ViewCount,
        cp.Comment AS ClosureComments
    FROM PostStatistics ps
    JOIN UserReputation ur ON ps.OwnerUserId = ur.Id
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
    WHERE ur.ReputationLevel = 'High'
)

SELECT 
    DisplayName, 
    COUNT(Title) AS TotalPosts, 
    AVG(Score) AS AvgScore, 
    SUM(COALESCE(AnswerCount, 0)) AS TotalAnswers,
    MAX(ViewCount) AS MaxViews,
    STRING_AGG(ClosureComments, ', ') AS ClosureRemarks
FROM CombinedResults
GROUP BY DisplayName
HAVING COUNT(Title) > 5
ORDER BY AvgScore DESC
LIMIT 10;
