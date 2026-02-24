WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END) AS Deletions
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,  
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,    
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    PS.PostCount,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.TotalViews,
    PS.TotalScore,
    US.BadgeCount,
    US.UpVotes,
    US.DownVotes,
    US.Deletions
FROM UserStats US
JOIN PostStats PS ON US.UserId = PS.OwnerUserId
JOIN Users U ON US.UserId = U.Id
ORDER BY U.Reputation DESC;