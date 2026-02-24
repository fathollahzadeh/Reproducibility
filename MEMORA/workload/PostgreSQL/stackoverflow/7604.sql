
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        QuestionsAsked,
        AnswersGiven,
        TotalBountyReceived,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    TU.QuestionsAsked,
    TU.AnswersGiven,
    TU.TotalBountyReceived
FROM 
    TopUsers TU
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UserRank;
