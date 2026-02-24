WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(P.Score) AS AverageScore
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        PositiveScoreCount,
        AverageScore
    FROM
        UserPostStats
    WHERE 
        PostCount > 0
    ORDER BY 
        Reputation DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UPost.PostCount,
    UPost.QuestionCount,
    UPost.AnswerCount,
    UPost.PositiveScoreCount,
    UPost.AverageScore
FROM 
    TopUsers UPost
JOIN 
    Users U ON U.Id = UPost.UserId;