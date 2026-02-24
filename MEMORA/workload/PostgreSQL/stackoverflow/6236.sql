WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpvoteCount,
        DownvoteCount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
)
SELECT
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.UpvoteCount,
    TU.DownvoteCount,
    AVG(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS AverageCloseReasons,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM TopUsers TU
LEFT JOIN PostHistory PH ON TU.UserId = PH.UserId
LEFT JOIN Badges B ON TU.UserId = B.UserId
WHERE TU.Rank <= 10
GROUP BY TU.Rank, TU.DisplayName, TU.Reputation, TU.PostCount, TU.QuestionCount, TU.AnswerCount, TU.UpvoteCount, TU.DownvoteCount
ORDER BY TU.Rank;
