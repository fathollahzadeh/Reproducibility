WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
), QuestionStats AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, P.Title
), UserReputationChanges AS (
    SELECT 
        H.UserId,
        COUNT(H.Id) AS EditsCount,
        MAX(H.CreationDate) AS LastEditDate
    FROM PostHistory H
    WHERE H.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY H.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.AnswerCount,
    U.QuestionCount,
    QS.Title,
    QS.TotalBounty,
    QS.CommentCount,
    COALESCE(URC.EditsCount, 0) AS TotalEdits,
    URC.LastEditDate,
    CASE 
        WHEN U.Reputation > 1000 THEN 'Gold'
        WHEN U.Reputation > 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS Badge
FROM UserStats U
JOIN QuestionStats QS ON U.QuestionCount > 0
LEFT JOIN UserReputationChanges URC ON U.UserId = URC.UserId
WHERE U.UserRank <= 10
ORDER BY U.Reputation DESC, QS.TotalBounty DESC;