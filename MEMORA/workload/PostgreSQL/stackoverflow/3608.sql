WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Score,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        CASE 
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.PostTypeId, P.Score, P.AcceptedAnswerId
),
PostActivity AS (
    SELECT 
        PS.PostId,
        PS.PostType,
        SUM(CASE WHEN PS.PostType = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PS.PostType = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(PS.Score) AS AverageScore
    FROM PostSummary PS
    GROUP BY PS.PostId, PS.PostType
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PHT.Name AS HistoryType,
        PH.Comment
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate >= cast('2024-10-01' as date) - interval '30 days'
),
UserPosts AS (
    SELECT 
        U.UserId,
        COUNT(P.Id) AS PostsCreated,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM UserReputation U
    LEFT JOIN Posts P ON U.UserId = P.OwnerUserId
    GROUP BY U.UserId
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    APR.TotalQuestions,
    APR.TotalAnswers,
    APR.AverageScore,
    UP.PostsCreated,
    UP.TotalScore,
    RPH.HistoryType,
    RPH.Comment
FROM UserReputation UR
JOIN PostActivity APR ON UR.UserId = APR.PostId
JOIN UserPosts UP ON UR.UserId = UP.UserId
LEFT JOIN RecentPostHistory RPH ON UR.UserId = RPH.UserId
ORDER BY UR.Reputation DESC, APR.AverageScore DESC;