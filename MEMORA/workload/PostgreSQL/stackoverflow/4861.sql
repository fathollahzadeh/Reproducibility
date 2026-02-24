WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalBounty,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        UserRank
    FROM UserScore
    WHERE UserRank <= 10
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(MAX(PH.CreationDate), '2000-01-01') AS LastEditDate,
        P.ViewCount,
        P.Score,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            WHEN P.AnswerCount = 0 THEN 'Unanswered'
            ELSE 'Answered'
        END AS Status
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score, P.ClosedDate, P.AnswerCount
)
SELECT 
    TU.DisplayName,
    TM.Title,
    TM.CommentCount,
    TM.LastEditDate,
    TM.ViewCount,
    TM.Score,
    TM.Status,
    TU.TotalBounty,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers
FROM TopUsers TU
JOIN PostMetrics TM ON TU.UserId = TM.PostId
WHERE (TM.Status = 'Answered' OR TM.Status = 'Unanswered')
ORDER BY TU.TotalBounty DESC, TM.Score DESC
LIMIT 5;
