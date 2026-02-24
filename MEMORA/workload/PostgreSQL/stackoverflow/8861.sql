WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        TotalPosts,
        PositivePosts,
        NegativePosts,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        TotalPosts > 10
)
SELECT 
    T.DisplayName, 
    T.Reputation,
    T.TotalPosts,
    T.PositivePosts,
    T.NegativePosts,
    T.UpVotes,
    T.DownVotes,
    (T.UpVotes * 1.0 / NULLIF(T.TotalPosts, 0)) * 100 AS UpVotePercentage,
    (T.DownVotes * 1.0 / NULLIF(T.TotalPosts, 0)) * 100 AS DownVotePercentage
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Rank;
