
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalVotes
    FROM 
        RankedUsers
    WHERE 
        PostRank <= 10
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(CASE WHEN P.PostTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    T.DisplayName,
    T.Reputation,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.CloseReopenCount,
    T.TotalVotes,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = T.UserId) AS CommentCount
FROM 
    TopUsers T
JOIN 
    PostStats PS ON T.UserId = PS.OwnerUserId
ORDER BY 
    T.Reputation DESC, T.TotalVotes DESC;
