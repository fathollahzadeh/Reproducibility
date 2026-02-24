
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViewCount,
        SUM(P.CommentCount) AS TotalComments
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    U.Id,
    U.DisplayName,
    U.Reputation,
    COALESCE(PS.TotalPosts, 0) AS PostsCreated,
    COALESCE(PS.TotalQuestions, 0) AS QuestionsAsked,
    COALESCE(PS.TotalAnswers, 0) AS AnswersGiven,
    COALESCE(PS.TotalScore, 0) AS Score,
    COALESCE(PS.TotalViewCount, 0) AS ViewCount,
    COALESCE(PS.TotalComments, 0) AS CommentCount,
    COALESCE(US.TotalBounties, 0) AS TotalBounties,
    COALESCE(US.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(US.TotalDownVotes, 0) AS TotalDownVotes
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
ORDER BY 
    U.Reputation DESC;
