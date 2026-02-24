WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views, U.UpVotes, U.DownVotes
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        CreationDate,
        Views,
        UpVotes,
        DownVotes,
        TotalUpVotes,
        TotalDownVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalComments,
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserScores
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    CreationDate, 
    Views, 
    UpVotes, 
    DownVotes, 
    TotalUpVotes, 
    TotalDownVotes, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalComments, 
    TotalBadges,
    ReputationRank,
    UpVoteRank,
    PostRank
FROM 
    RankedUsers
WHERE 
    TotalPosts > 10
ORDER BY 
    ReputationRank, PostRank;
