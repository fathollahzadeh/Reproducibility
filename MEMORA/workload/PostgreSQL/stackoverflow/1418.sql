
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.*,
        RANK() OVER (ORDER BY (TotalUpVotes - TotalDownVotes) DESC) AS UserRanking
    FROM 
        UserActivity UA
)
SELECT 
    TU.DisplayName,
    TU.PostsCount,
    TU.AnswersCount,
    TU.AcceptedQuestions,
    TU.TotalUpVotes,
    TU.TotalDownVotes,
    CASE 
        WHEN TU.UserRanking <= 10 THEN 'Top Contributor'
        WHEN TU.UserRanking <= 50 THEN 'Regular Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    TopUsers TU
WHERE 
    TU.PostsCount > 5
ORDER BY 
    TU.UserRanking;
