WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
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
        TotalViews,
        AvgScore,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPostCount,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByTotalViews,
        RANK() OVER (ORDER BY AvgScore DESC) AS RankByAvgScore
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    AvgScore,
    QuestionCount,
    AnswerCount,
    RankByPostCount,
    RankByTotalViews,
    RankByAvgScore
FROM 
    TopUsers
WHERE 
    RankByPostCount <= 10 OR RankByTotalViews <= 10 OR RankByAvgScore <= 10
ORDER BY 
    RankByPostCount, RankByTotalViews, RankByAvgScore;