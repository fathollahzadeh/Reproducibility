WITH UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE 
            WHEN V.VoteTypeId IN (6, 10) THEN 1 
            ELSE 0 
        END) AS CloseVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PC.CommentCount, 0) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS TotalPosts 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1 
        GROUP BY 
            OwnerUserId
    ) PS ON P.OwnerUserId = PS.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) PC ON P.Id = PC.PostId
)
SELECT 
    U.DisplayName,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    UVS.TotalVotes,
    UVS.UpVotes,
    UVS.DownVotes,
    UVS.CloseVotes
FROM 
    UserVoteStatistics UVS
JOIN 
    Posts PS ON UVS.TotalVotes > 0
LEFT JOIN 
    Users U ON PS.OwnerUserId = U.Id
WHERE 
    PS.Score > 10
ORDER BY 
    PS.ViewCount DESC,
    UVS.UpVotes DESC
LIMIT 100;