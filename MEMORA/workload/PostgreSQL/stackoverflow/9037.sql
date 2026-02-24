WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS NumberOfPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBountyEarned,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    WHERE 
        U.Reputation > 100  
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        NumberOfPosts, 
        AnswerCount, 
        QuestionCount, 
        TotalBountyEarned, 
        LastPostDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    NumberOfPosts, 
    AnswerCount, 
    QuestionCount, 
    TotalBountyEarned, 
    LastPostDate
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10  
ORDER BY 
    Reputation DESC;