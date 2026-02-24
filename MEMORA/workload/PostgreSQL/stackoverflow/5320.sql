
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsMade,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VotesReceived, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCreated,
        AnswersGiven,
        QuestionsAsked,
        CommentsMade,
        VotesReceived,
        ReputationRank
    FROM 
        UserActivity
    WHERE 
        Reputation > 100 
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.PostsCreated,
    T.AnswersGiven,
    T.QuestionsAsked,
    T.CommentsMade,
    T.VotesReceived,
    T.ReputationRank,
    PT.Name AS PostTypeName,
    COUNT(P.Id) AS TotalPostsOfType
FROM 
    TopUsers T
LEFT JOIN 
    Posts P ON T.UserId = P.OwnerUserId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, 
    T.PostsCreated, T.AnswersGiven, 
    T.QuestionsAsked, T.CommentsMade, 
    T.VotesReceived, T.ReputationRank, 
    PT.Name
ORDER BY 
    T.Reputation DESC, 
    TotalPostsOfType DESC
LIMIT 10;
