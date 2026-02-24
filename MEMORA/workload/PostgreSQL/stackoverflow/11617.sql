
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate, U.Views, U.UpVotes, U.DownVotes
), VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes V
    GROUP BY 
        PostId
)
SELECT 
    US.UserId,
    US.Reputation,
    US.CreationDate,
    US.Views,
    US.UpVotes,
    US.DownVotes,
    US.TotalPosts,
    US.TotalComments,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalBadges,
    COALESCE(VS.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(VS.TotalDownVotes, 0) AS TotalDownVotes
FROM 
    UserStats US
LEFT JOIN 
    VoteStats VS ON US.UserId = VS.PostId
ORDER BY 
    US.Reputation DESC;
