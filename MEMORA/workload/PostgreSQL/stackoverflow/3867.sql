
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        CT.Name AS CloseReason
    FROM PostHistory PH
    INNER JOIN Posts P ON PH.PostId = P.Id
    LEFT JOIN CloseReasonTypes CT ON CAST(PH.Comment AS integer) = CT.Id
    WHERE PH.PostHistoryTypeId = 10
),
UserClosedPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CP.PostId) AS ClosedPostCount
    FROM Users U
    LEFT JOIN ClosedPosts CP ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = CP.PostId)
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalScore,
    COALESCE(UCP.ClosedPostCount, 0) AS ClosedPostCount
FROM TopUsers TU
LEFT JOIN UserClosedPosts UCP ON TU.UserId = UCP.UserId
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC, TU.TotalScore DESC
LIMIT 10;
