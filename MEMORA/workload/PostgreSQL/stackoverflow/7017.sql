
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
ActiveUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserStatistics
    WHERE 
        PostCount > 0
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore
    FROM 
        ActiveUsers
    WHERE 
        Rank <= 10
)
SELECT 
    U.DisplayName, 
    U.Reputation AS UserReputation,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalScore,
    COALESCE(C.CommentCount, 0) AS CommentCount,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers TU
JOIN 
    Users U ON TU.UserId = U.Id
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         UserId) C ON U.Id = C.UserId
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) B ON U.Id = B.UserId
ORDER BY 
    TU.TotalScore DESC;
