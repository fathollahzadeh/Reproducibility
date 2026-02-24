WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) FILTER (WHERE P.ClosedDate IS NOT NULL) AS ClosedPosts
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        US.UpVotes,
        US.DownVotes,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.TotalScore,
        PS.ClosedPosts
    FROM UserStats US
    FULL OUTER JOIN PostStats PS ON US.UserId = PS.OwnerUserId
    JOIN Users U ON COALESCE(US.UserId, PS.OwnerUserId) = U.Id
)
SELECT 
    C.DisplayName,
    C.Reputation,
    C.UpVotes,
    C.DownVotes,
    C.TotalPosts,
    C.Questions,
    C.Answers,
    C.TotalScore,
    C.ClosedPosts,
    CASE 
        WHEN C.Questions > 0 THEN ROUND(CAST(C.ClosedPosts AS DECIMAL) / C.Questions, 2) 
        ELSE NULL 
    END AS ClosedToQuestionRatio,
    CASE 
        WHEN C.Answers > 0 THEN ROUND(CAST(C.ClosedPosts AS DECIMAL) / C.Answers, 2) 
        ELSE NULL 
    END AS ClosedToAnswerRatio
FROM CombinedStats C
WHERE C.Reputation > 100
ORDER BY C.Reputation DESC
LIMIT 50;
