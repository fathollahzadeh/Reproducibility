
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COALESCE(SUM(B.Class), 0) AS TotalBadges, 
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
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
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalUpVotes, 
        TotalDownVotes, 
        TotalBadges, 
        TotalComments,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalUpVotes DESC) AS PostRank
    FROM 
        UserStatistics
)
SELECT 
    UserId, 
    DisplayName, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalUpVotes, 
    TotalDownVotes, 
    TotalBadges, 
    TotalComments,
    PostRank
FROM 
    TopUsers
WHERE 
    PostRank <= 10
ORDER BY 
    PostRank;
