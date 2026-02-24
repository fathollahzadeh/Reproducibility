WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        (P.Score + COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) - COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3)) AS AdjustedScore
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
TopUsers AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        RANK() OVER (ORDER BY US.Reputation DESC) AS Rank
    FROM 
        UserStats US
    WHERE 
        US.TotalPosts > 0
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    COALESCE(AVG(PD.AdjustedScore), 0) AS AvgPostScore,
    COALESCE(SUM(CASE WHEN PD.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePostCount
FROM 
    TopUsers TU
LEFT JOIN 
    PostDetails PD ON TU.UserId = PD.OwnerUserId
GROUP BY 
    TU.Rank, TU.DisplayName, TU.Reputation
ORDER BY 
    TU.Rank
LIMIT 10;
