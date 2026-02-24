
WITH PostMetrics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.Score) AS AvgScore,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY PT.Name
),
UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    GROUP BY U.Id, U.DisplayName
),
VoteMetrics AS (
    SELECT 
        VT.Name AS VoteType,
        COUNT(V.Id) AS TotalVotes,
        AVG(V.BountyAmount) AS AvgBounty
    FROM Votes V
    JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY VT.Name
)

SELECT 
    'Post Metrics' AS MetricType,
    PM.PostType,
    PM.TotalPosts,
    PM.AvgViewCount,
    PM.AvgScore,
    PM.TotalAcceptedAnswers
FROM PostMetrics PM

UNION ALL

SELECT 
    'User Metrics' AS MetricType,
    U.DisplayName AS PostType,
    U.PostCount AS TotalPosts,
    NULL AS AvgViewCount,
    NULL AS AvgScore,
    U.TotalBounty AS TotalAcceptedAnswers
FROM UserMetrics U

UNION ALL

SELECT 
    'Vote Metrics' AS MetricType,
    VM.VoteType AS PostType,
    VM.TotalVotes,
    NULL AS AvgViewCount,
    VM.AvgBounty AS AvgScore,
    NULL AS TotalAcceptedAnswers
FROM VoteMetrics VM;
