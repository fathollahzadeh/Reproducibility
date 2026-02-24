WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount,
        COUNT(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS ScoreRank
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
        TotalScore, 
        AvgViewCount, 
        AcceptedAnswers 
    FROM 
        UserPostStats 
    WHERE 
        ScoreRank <= 10
),
CommentStats AS (
    SELECT 
        C.UserId, 
        COUNT(C.Id) AS CommentCount,
        AVG(C.Score) AS AvgCommentScore
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
UserPerformance AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.PostCount,
        U.TotalScore,
        U.AvgViewCount,
        U.AcceptedAnswers,
        COALESCE(C.CommentCount, 0) AS TotalComments,
        COALESCE(C.AvgCommentScore, 0) AS AvgCommentScore
    FROM 
        TopUsers U
    LEFT JOIN 
        CommentStats C ON U.UserId = C.UserId
)
SELECT 
    UP.DisplayName,
    UP.PostCount,
    UP.TotalScore,
    UP.AvgViewCount,
    UP.AcceptedAnswers,
    UP.TotalComments,
    UP.AvgCommentScore
FROM 
    UserPerformance UP
WHERE 
    UP.TotalScore > (SELECT AVG(TotalScore) FROM UserPostStats)
ORDER BY 
    UP.TotalScore DESC
OFFSET 5 ROWS
FETCH NEXT 5 ROWS ONLY;
