
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS TotalAnswerScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Questions,
        Answers,
        TotalQuestionScore,
        TotalAnswerScore
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),
TopPosters AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        ActiveUsers
),
TopQuestions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TopQuestionCount
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
),
TopAnswers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TopAnswerCount
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 2
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.Questions,
    T.Answers,
    T.TotalQuestionScore,
    T.TotalAnswerScore,
    COALESCE(Q.TopQuestionCount, 0) AS TopQuestionCount,
    COALESCE(A.TopAnswerCount, 0) AS TopAnswerCount
FROM 
    TopPosters T
LEFT JOIN 
    TopQuestions Q ON T.UserId = Q.UserId
LEFT JOIN 
    TopAnswers A ON T.UserId = A.UserId
WHERE 
    T.PostRank <= 10
ORDER BY 
    T.PostCount DESC, T.Reputation DESC;
