
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswersCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        AnswerCount,
        QuestionCount,
        AcceptedAnswersCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        P.Title,
        COUNT(*) AS ChangeCount,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY PH.PostId, PH.PostHistoryTypeId, P.Title
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.AnswerCount,
    TU.QuestionCount,
    TU.AcceptedAnswersCount,
    TU.CommentCount,
    COALESCE(RP.Title, 'No Recent Posts') AS RecentPostTitle,
    COALESCE(RP.CreationDate, CURRENT_TIMESTAMP) AS RecentPostCreation,
    COALESCE(RP.Score, 0) AS RecentPostScore,
    COALESCE(RP.ViewCount, 0) AS RecentPostViewCount,
    PHS.ChangeCount,
    PHS.LastChangeDate
FROM TopUsers TU
LEFT JOIN RecentPosts RP ON TU.DisplayName = RP.OwnerDisplayName
LEFT JOIN PostHistorySummary PHS ON RP.PostId = PHS.PostId
WHERE TU.Reputation > 1000
ORDER BY TU.Rank;
