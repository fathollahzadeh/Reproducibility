WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
), BestUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        UpVotes, 
        DownVotes, 
        TotalPosts, 
        TotalComments,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS RankUpDown
    FROM 
        UserVoteStats
)
SELECT 
    U.DisplayName, 
    U.Reputation, 
    B.TotalPosts, 
    B.TotalComments, 
    B.UpVotes, 
    B.DownVotes,
    CASE 
        WHEN B.RankUpDown <= 10 THEN 'Top Users'
        ELSE 'Regular Users'
    END AS UserCategory
FROM 
    BestUsers B
JOIN 
    Users U ON B.UserId = U.Id
WHERE 
    U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
ORDER BY 
    B.RankUpDown
LIMIT 20;