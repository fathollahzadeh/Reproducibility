
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVoteScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.NetVoteScore,
        ROW_NUMBER() OVER (ORDER BY PS.NetVoteScore DESC, PS.CommentCount DESC) AS Rank
    FROM 
        PostStatistics PS
)
SELECT 
    U.DisplayName,
    U.UpVoteCount,
    U.DownVoteCount,
    TP.Title,
    TP.CommentCount,
    TP.NetVoteScore
FROM 
    UserVoteStats U
JOIN 
    TopPosts TP ON U.UserId = TP.PostId
WHERE 
    TP.Rank <= 10
ORDER BY 
    U.DisplayName, TP.NetVoteScore DESC;
