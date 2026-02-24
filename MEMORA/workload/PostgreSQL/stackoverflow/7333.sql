
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserPostStats
),
PopularQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
        AND P.ViewCount > 1000  
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalViews,
    TU.AverageScore,
    PQ.Title AS PopularQuestionTitle,
    PQ.ViewCount AS PopularQuestionViews,
    PQ.Score AS PopularQuestionScore,
    PQ.OwnerDisplayName AS PopularQuestionOwner
FROM 
    TopUsers TU
CROSS JOIN 
    PopularQuestions PQ
WHERE 
    TU.PostRank <= 10
ORDER BY 
    TU.PostCount DESC, PQ.ViewCount DESC;
