
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(UPV.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(DNV.DownVoteCount, 0) AS DownVoteCount,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS UpVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) UPV ON P.Id = UPV.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS DownVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) DNV ON P.Id = DNV.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, UPV.UpVoteCount, DNV.DownVoteCount
)
SELECT 
    U.DisplayName,
    UReputation.TotalPosts AS Reputation,
    PS.PostId,
    PS.Title,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.CommentCount
FROM 
    UserVoteStats UReputation
JOIN 
    Users U ON U.Id = UReputation.UserId
JOIN 
    PostDetails PS ON PS.PostRank <= 5 AND PS.UpVoteCount > PS.DownVoteCount
WHERE 
    UReputation.TotalPosts > 10
ORDER BY 
    UReputation.UpVotes DESC, PS.UpVoteCount DESC
LIMIT 10;
