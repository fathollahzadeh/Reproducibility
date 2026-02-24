
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE
        P.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(RP.Upvotes, 0)) AS TotalUpvotes,
        SUM(COALESCE(RP.Downvotes, 0)) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        RankedPosts RP ON U.Id = RP.OwnerUserId
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.TotalQuestions,
        U.TotalViews,
        U.TotalAnswers,
        U.TotalComments,
        U.TotalUpvotes,
        U.TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC, U.TotalUpvotes DESC) AS UserRank
    FROM 
        UserStats U
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalQuestions,
    TU.TotalViews,
    TU.TotalAnswers,
    TU.TotalComments,
    TU.TotalUpvotes,
    TU.TotalDownvotes
FROM 
    TopUsers TU
WHERE
    TU.UserRank <= 10 
ORDER BY 
    TU.UserRank;
