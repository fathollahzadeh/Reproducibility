
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(P.CreationDate) AS LastPostDate,
        SUM(COALESCE(CM.Score, 0)) AS TotalCommentScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
CloseReasonAggregates AS (
    SELECT 
        PH.UserId,
        PH.PostHistoryTypeId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CR ON CAST(PH.Comment AS INT) = CR.Id
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.UserId, PH.PostHistoryTypeId
),
PostLinkStats AS (
    SELECT 
        PL.PostId,
        COUNT(*) AS LinkCount,
        MAX(PL.CreationDate) AS LastLinkDate
    FROM PostLinks PL
    GROUP BY PL.PostId
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.LastPostDate,
    COALESCE(CRA.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(CRA.CloseReasons, 'None') AS CloseReasons,
    COALESCE(PLS.LinkCount, 0) AS TotalLinks,
    PLS.LastLinkDate,
    EXTRACT(YEAR FROM AGE(UA.LastPostDate)) AS YearsSinceLastPost,
    CASE 
        WHEN UA.Reputation > 2000 THEN 'High Reputation'
        WHEN UA.Reputation > 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserActivity UA
LEFT JOIN CloseReasonAggregates CRA ON UA.UserId = CRA.UserId
LEFT JOIN PostLinkStats PLS ON UA.PostCount > 0 AND (UA.PostCount % 3 = 0)  
WHERE UA.Reputation IS NOT NULL
ORDER BY UA.Reputation DESC, UA.PostCount DESC
LIMIT 100;
