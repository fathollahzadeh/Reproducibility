
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsMade,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        COUNT(DISTINCT B.Id) AS BadgesCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        QuestionsAsked, 
        AnswersGiven, 
        CommentsMade, 
        UpvotesReceived, 
        DownvotesReceived, 
        BadgesCount,
        ROW_NUMBER() OVER (ORDER BY UpvotesReceived - DownvotesReceived DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    TU.Rank, 
    TU.DisplayName, 
    TU.QuestionsAsked, 
    TU.AnswersGiven, 
    TU.CommentsMade, 
    TU.UpvotesReceived, 
    TU.DownvotesReceived, 
    TU.BadgesCount
FROM 
    TopUsers TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank;
