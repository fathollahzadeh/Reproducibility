
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY MAX(P.LastActivityDate) DESC) AS ActivityRank
    FROM 
        UserStats
    JOIN 
        Posts P ON UserStats.UserId = P.OwnerUserId
    GROUP BY 
        UserId, DisplayName, Reputation
    HAVING 
        MAX(P.LastActivityDate) > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAY')
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        ActivityRank
    FROM 
        RecentActiveUsers
    WHERE 
        ActivityRank <= 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.QuestionCount,
    U.AnswerCount,
    U.VoteCount,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    UserStats U
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) B ON U.UserId = B.UserId
WHERE 
    U.UserId IN (SELECT UserId FROM TopUsers)
ORDER BY 
    U.Reputation DESC, U.TotalPosts DESC;
