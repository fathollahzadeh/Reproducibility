WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(V.VoteCount) AS AvgVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalScore,
    U.AvgVoteCount
FROM 
    UserPostStats U
ORDER BY 
    U.TotalScore DESC
LIMIT 10;