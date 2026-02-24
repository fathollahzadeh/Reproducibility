WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 50
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        TotalPosts,
        Questions,
        Answers,
        AcceptedQuestions,
        BadgesCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserMetrics
)
SELECT 
    M.UserId,
    M.DisplayName,
    M.Reputation,
    M.CreationDate,
    M.TotalPosts,
    M.Questions,
    M.Answers,
    M.AcceptedQuestions,
    M.BadgesCount
FROM 
    MostActiveUsers M
WHERE 
    M.PostRank <= 10
ORDER BY 
    M.PostRank;
