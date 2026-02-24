WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        Upvotes,
        Downvotes,
        TotalPosts,
        AvgPostScore,
        RANK() OVER (ORDER BY TotalVotes DESC) AS UserRank
    FROM 
        UserVoteStats
)
SELECT 
    T.DisplayName,
    T.TotalVotes,
    T.Upvotes,
    T.Downvotes,
    T.TotalPosts,
    T.AvgPostScore,
    COALESCE(CASE WHEN T.UserRank <= 10 THEN 'Top Contributor' ELSE 'Regular Contributor' END, 'Unknown') AS ContributorType
FROM 
    TopUsers T
WHERE 
    T.TotalVotes > 5
UNION ALL
SELECT 
    U.DisplayName,
    0 AS TotalVotes,
    0 AS Upvotes,
    0 AS Downvotes,
    0 AS TotalPosts,
    0 AS AvgPostScore,
    'Inactive Contributor' AS ContributorType
FROM 
    Users U
WHERE 
    NOT EXISTS (SELECT 1 FROM Votes V WHERE V.UserId = U.Id)
    AND U.LastAccessDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
ORDER BY 
    TotalVotes DESC NULLS LAST;