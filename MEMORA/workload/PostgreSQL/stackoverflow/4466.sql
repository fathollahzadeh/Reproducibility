
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalUpVotes,
        TotalDownVotes,
        UserRank
    FROM 
        UserStatistics
    WHERE 
        TotalPosts > 5
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.Reputation,
    A.TotalPosts,
    A.TotalAnswers,
    A.TotalQuestions,
    A.TotalUpVotes,
    A.TotalDownVotes,
    A.UserRank,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    COALESCE(C.CommentCount, 0) AS CommentCount
FROM 
    MostActiveUsers A
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(Id) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) B ON A.UserId = B.UserId
LEFT JOIN 
    (SELECT 
         UserId, COUNT(Id) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         UserId) C ON A.UserId = C.UserId
WHERE 
    A.Reputation BETWEEN 1000 AND 10000
ORDER BY 
    A.Reputation DESC, A.UserRank ASC
LIMIT 10;
