WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostId IS NOT NULL THEN 1 END), 0) AS HistoryCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.PostCount,
    UR.QuestionCount,
    UR.AnswerCount,
    UR.Upvotes,
    UR.Downvotes,
    PA.PostId,
    PA.Title AS PostTitle,
    PA.CreationDate AS PostCreationDate,
    PA.ViewCount AS PostViewCount,
    PA.CommentCount,
    PA.HistoryCount
FROM UserReputation UR
JOIN PostAnalytics PA ON UR.UserId = PA.PostId
ORDER BY UR.Reputation DESC, PA.ViewCount DESC
LIMIT 50;
