
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(U.Reputation) AS AvgReputation,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVoteCount,
        DownVoteCount,
        AvgReputation,
        LastPostDate
    FROM
        UserActivity
    WHERE 
        PostCount > 0
    ORDER BY 
        UpVoteCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.UpVoteCount,
    TU.DownVoteCount,
    TU.AvgReputation,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.AvgScore,
    PS.CommentCount,
    TU.LastPostDate
FROM 
    TopUsers TU
JOIN 
    PostStatistics PS ON TU.UserId = PS.OwnerUserId
ORDER BY 
    TU.UpVoteCount DESC, 
    PS.AvgScore DESC;
