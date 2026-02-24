
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        Us.*,
        RANK() OVER (ORDER BY Us.Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN Us.Reputation > 1000 THEN 'Elite' ELSE 'Novice' END ORDER BY Us.TotalPosts DESC) AS PostRank
    FROM UserStats Us
),
PostHistoryAggregates AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(PH.Comment, '; ') AS Comments
    FROM PostHistory PH
    GROUP BY PH.UserId
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        PH.CreationDate AS CloseDate,
        CRT.Name AS CloseReason
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS int) = CRT.Id
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.ReputationRank,
    RU.PostRank,
    COALESCE(PH.HistoryCount, 0) AS PostHistoryCount,
    COALESCE(PH.Comments, '') AS UserComments,
    COUNT(DISTINCT CP.PostId) AS ClosedPostCount,
    SUM(CASE WHEN CP.CloseDate > CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentlyClosedPosts
FROM RankedUsers RU
LEFT JOIN PostHistoryAggregates PH ON RU.UserId = PH.UserId
LEFT JOIN ClosedPosts CP ON RU.UserId = CP.OwnerUserId
GROUP BY RU.UserId, RU.DisplayName, RU.Reputation, RU.ReputationRank, RU.PostRank, PH.HistoryCount, PH.Comments
ORDER BY RU.Reputation DESC, ClosedPostCount DESC;
