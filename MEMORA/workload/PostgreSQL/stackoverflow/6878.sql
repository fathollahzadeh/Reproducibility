WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(V.Id) AS TotalVotes, 
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.OwnerUserId, 
        COUNT(C.Id) AS CommentCount, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        S.TotalVotes, 
        S.UpVotes, 
        S.DownVotes
    FROM 
        Users U
    JOIN 
        UserVoteSummary S ON U.Id = S.UserId
    WHERE 
        S.TotalVotes > 10
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
)
SELECT 
    PS.PostId, 
    PS.Title, 
    PS.CreationDate, 
    T.DisplayName AS Owner, 
    PS.CommentCount,
    PS.UpVotes, 
    PS.DownVotes
FROM 
    PostSummary PS
JOIN 
    TopUsers T ON PS.OwnerUserId = T.UserId
ORDER BY 
    PS.CreationDate DESC;