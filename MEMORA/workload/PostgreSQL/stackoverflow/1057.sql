
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.AcceptedAnswerId,
        COUNT(CM.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    WHERE P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName, P.AcceptedAnswerId
),
AcceptedAnswers AS (
    SELECT 
        P.Id AS AnswerId,
        P.ParentId AS QuestionId,
        P.OwnerUserId,
        U.DisplayName AS AnswerOwner
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.AcceptedAnswerId IS NOT NULL
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PHT.Name AS PostHistoryType,
        PH.CreationDate
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.CommentCount,
    UR.DisplayName AS TopUser,
    UR.Reputation AS TopUserReputation,
    PH.UserId AS HistoryUser,
    PH.PostHistoryType,
    PH.CreationDate AS HistoryDate,
    A.AnswerOwner,
    A.AnswerId
FROM RecentPosts RP
LEFT JOIN UserReputation UR ON UR.Rank = 1
LEFT JOIN PostHistoryDetails PH ON RP.PostId = PH.PostId
LEFT JOIN AcceptedAnswers A ON A.QuestionId = RP.PostId
WHERE RP.Score > 10
ORDER BY RP.ViewCount DESC, RP.CreationDate DESC
LIMIT 100;
