WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
FinalComparison AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Reputation,
        TU.PostsCreated,
        TU.QuestionsAsked,
        TU.AnswersProvided,
        UB.TotalBadges,
        TU.ReputationRank
    FROM 
        TopUsers TU
    LEFT JOIN 
        UserBadges UB ON TU.UserId = UB.UserId
)
SELECT 
    DisplayName,
    Reputation,
    PostsCreated,
    QuestionsAsked,
    AnswersProvided,
    TotalBadges,
    ReputationRank
FROM 
    FinalComparison
WHERE 
    TotalBadges > 5
ORDER BY 
    ReputationRank;
