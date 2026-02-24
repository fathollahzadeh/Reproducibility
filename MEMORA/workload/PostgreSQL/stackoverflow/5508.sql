WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        DisplayName,
        TotalViews,
        QuestionCount,
        AnswerCount,
        TotalCommentScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank,
        RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank
    FROM 
        UserEngagement
)
SELECT 
    DisplayName,
    TotalViews,
    QuestionCount,
    AnswerCount,
    TotalCommentScore,
    ViewRank,
    QuestionRank,
    AnswerRank
FROM 
    TopUsers
WHERE 
    ViewRank <= 10 OR QuestionRank <= 10 OR AnswerRank <= 10
ORDER BY 
    ViewRank, QuestionRank, AnswerRank;
