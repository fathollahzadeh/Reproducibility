WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        QuestionCount, 
        AnswerCount, 
        CommentCount, 
        TotalViews, 
        AvgScore, 
        BadgeCount,
        DENSE_RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        DENSE_RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank,
        DENSE_RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank
    FROM 
        UserActivity
)
SELECT 
    UserId, 
    DisplayName, 
    QuestionCount, 
    AnswerCount, 
    CommentCount, 
    TotalViews, 
    AvgScore, 
    BadgeCount,
    ViewRank,
    QuestionRank,
    AnswerRank
FROM 
    TopUsers
WHERE 
    ViewRank <= 10 OR QuestionRank <= 10 OR AnswerRank <= 10
ORDER BY 
    ViewRank, QuestionRank, AnswerRank;
