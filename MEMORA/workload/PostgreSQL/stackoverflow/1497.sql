WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes, U.Views
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UserRank
    FROM UserStats
    WHERE UserRank <= 100
),
QuestionStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteCount
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    COALESCE(QS.CloseCount, 0) AS CloseCount,
    COALESCE(QS.ReopenCount, 0) AS ReopenCount,
    COALESCE(QS.DeleteCount, 0) AS DeleteCount,
    (TU.Reputation + COALESCE(QS.CloseCount, 0) * -5 + COALESCE(QS.ReopenCount, 0) * 5 + COALESCE(QS.DeleteCount, 0) * -10) AS AdjustedReputation
FROM TopUsers TU
LEFT JOIN QuestionStats QS ON TU.UserId = QS.OwnerUserId
ORDER BY AdjustedReputation DESC
LIMIT 50;
