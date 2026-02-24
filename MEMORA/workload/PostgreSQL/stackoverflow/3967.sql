
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(AVG(P.Score), 0) AS AveragePostScore,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
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
        TotalVotes, 
        UpVotes, 
        DownVotes, 
        AveragePostScore,
        VoteRank
    FROM 
        UserVoteStats
    WHERE 
        TotalVotes > 0
    ORDER BY 
        TotalVotes DESC
    LIMIT 10
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS DownVotes,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.OwnerUserId IS NOT NULL
)
SELECT 
    U.DisplayName AS TopUser,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    P.Score AS PostScore,
    P.CommentCount AS TotalComments,
    P.UpVotes AS TotalUpVotes,
    P.DownVotes AS TotalDownVotes
FROM 
    TopUsers U
INNER JOIN 
    PostSummary P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.TotalVotes DESC, 
    P.Score DESC
LIMIT 5;
