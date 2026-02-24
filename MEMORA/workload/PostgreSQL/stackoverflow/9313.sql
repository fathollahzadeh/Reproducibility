
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation AS Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        U.UserId, 
        U.Reputation, 
        U.PostCount, 
        U.TotalScore, 
        U.QuestionCount, 
        U.AnswerCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation U
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        C.CommentCount
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    INNER JOIN 
        PostsWithComments C ON P.Id = C.PostId
)
SELECT 
    T.UserId,
    T.Reputation,
    T.PostCount,
    T.TotalScore,
    T.QuestionCount,
    T.AnswerCount,
    T.ReputationRank,
    U.DisplayName,
    U.Title,
    U.CreationDate,
    U.CommentCount
FROM 
    TopUsers T
JOIN 
    UserPostDetails U ON T.UserId = U.UserId
ORDER BY 
    T.Reputation DESC, U.CommentCount DESC
FETCH FIRST 100 ROWS ONLY;
