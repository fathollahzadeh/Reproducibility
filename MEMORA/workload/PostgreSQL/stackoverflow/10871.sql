
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikisCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.PostCount,
    U.QuestionsCount,
    U.AnswersCount,
    U.WikisCount,
    U.TotalVotes,
    U.LastPostDate,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
FROM 
    UserStats U
ORDER BY 
    U.Reputation DESC
FETCH FIRST 100 ROWS ONLY;
