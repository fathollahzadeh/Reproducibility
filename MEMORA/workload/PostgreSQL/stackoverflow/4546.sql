WITH UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), 
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, QuestionCount, AnswerCount, TotalBounties, UserRank
    FROM UserSummary
    WHERE UserRank <= 10
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        MAX(PH.CreationDate) AS LastHistoryDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalBounties,
    P.Title,
    P.CommentCount,
    P.VoteCount,
    P.LastHistoryDate
FROM TopUsers T
JOIN PostStats P ON P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
LEFT JOIN UserSummary U ON T.UserId = U.UserId
ORDER BY T.Reputation DESC, P.VoteCount DESC;