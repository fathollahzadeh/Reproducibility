
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY P.Id, P.Title, P.CreationDate
),
PostHistoryStats AS (
    SELECT
        PH.PostId,
        COUNT(PH.Id) AS TotalEdits,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalComments,
    UA.TotalBounties,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.TotalComments AS PostTotalComments,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    PHS.TotalEdits,
    PHS.LastEditDate
FROM UserActivity UA
JOIN PostStats PS ON UA.TotalQuestions > 0
LEFT JOIN PostHistoryStats PHS ON PS.PostId = PHS.PostId
ORDER BY UA.TotalPosts DESC, UA.DisplayName
LIMIT 100;
