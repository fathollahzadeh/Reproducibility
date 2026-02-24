
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
)
SELECT 
    U.DisplayName AS User_Name,
    U.Reputation AS User_Reputation,
    P.Title AS Post_Title,
    P.TotalComments AS Comments_Count,
    (P.TotalUpVotes - P.TotalDownVotes) AS NetVotes,
    T.UserRank AS User_Rank,
    COALESCE(P.RecentPostRank, 0) AS Recent_Post_Rank
FROM 
    UserVoteStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    TopUsers T ON U.DisplayName = T.DisplayName
WHERE 
    U.TotalVotes > 50
    AND (P.TotalUpVotes - P.TotalDownVotes) > 0
ORDER BY 
    U.Reputation DESC, 
    P.TotalComments DESC;
