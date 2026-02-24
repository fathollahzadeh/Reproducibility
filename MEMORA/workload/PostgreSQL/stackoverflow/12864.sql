
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        U.Views, 
        U.UpVotes, 
        U.DownVotes, 
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostTypesStats AS (
    SELECT 
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViewCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
)
SELECT 
    U.UserId,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.AcceptedAnswerCount,
    PTS.PostTypeName,
    PTS.TotalPosts,
    PTS.TotalViewCount,
    PTS.AverageScore
FROM 
    UserStats U
CROSS JOIN 
    PostTypesStats PTS
ORDER BY 
    U.Reputation DESC, 
    PTS.TotalPosts DESC;
