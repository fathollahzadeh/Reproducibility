WITH RECURSIVE UserScoreCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000  

    UNION ALL

    SELECT 
        U.Id,
        U.Reputation,
        U.DisplayName,
        Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserScoreCTE USC ON U.Id = USC.UserId
    WHERE 
        USC.Level < 5 AND 
        U.Reputation > USC.Reputation * 1.5  
), 

PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),

UserActivity AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.QuestionCount, 0) AS QuestionCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        U.Reputation
    FROM 
        Users U
    LEFT JOIN 
        PostStats P ON U.Id = P.OwnerUserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.QuestionCount,
    U.AnswerCount,
    CASE 
        WHEN U.Reputation > 2000 THEN 'High'
        WHEN U.Reputation BETWEEN 1000 AND 2000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.Id) AS TotalVotes,
    (SELECT STRING_AGG(DISTINCT PT.Name, ', ') 
     FROM Posts P
     INNER JOIN PostTypes PT ON P.PostTypeId = PT.Id
     WHERE P.OwnerUserId = U.Id) AS PostTypes
FROM 
    UserActivity U
WHERE 
    U.Reputation IS NOT NULL
ORDER BY 
    U.Reputation DESC;