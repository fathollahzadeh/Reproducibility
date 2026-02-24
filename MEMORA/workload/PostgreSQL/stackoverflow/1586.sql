
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8 
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.AcceptedAnswerId,
        COALESCE(A.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    LEFT JOIN Posts A ON P.AcceptedAnswerId = A.Id
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1 
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(CRT.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS INT) = CRT.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
),
AggregatedPostStats AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        PD.AnswerCount,
        PD.CommentCount,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        CP.CloseReasons
    FROM PostDetails PD
    LEFT JOIN ClosedPosts CP ON PD.PostId = CP.PostId
)
SELECT 
    US.DisplayName AS UserName,
    US.Reputation,
    US.TotalPosts,
    US.TotalBountyAmount,
    APS.Title AS PostTitle,
    APS.CreationDate AS PostCreationDate,
    APS.Score AS PostScore,
    APS.ViewCount AS PostViewCount,
    APS.AnswerCount AS PostAnswerCount,
    APS.CloseCount,
    APS.CloseReasons,
    ROW_NUMBER() OVER (PARTITION BY US.UserId ORDER BY APS.CreationDate DESC) AS UserPostRank
FROM UserStatistics US
JOIN AggregatedPostStats APS ON US.DisplayName = APS.OwnerDisplayName
WHERE US.TotalPosts > 0
ORDER BY US.Reputation DESC, APS.Score DESC
LIMIT 100;
