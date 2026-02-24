WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        MAX(U.Reputation) AS MaxReputation
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpVotes,
        TotalDownVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        MaxReputation,
        ROW_NUMBER() OVER (ORDER BY MaxReputation DESC) AS Rank
    FROM 
        UserVoteSummary
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalUpVotes,
    T.TotalDownVotes,
    T.TotalPosts,
    T.TotalQuestions,
    T.TotalAnswers,
    T.MaxReputation
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.MaxReputation DESC;