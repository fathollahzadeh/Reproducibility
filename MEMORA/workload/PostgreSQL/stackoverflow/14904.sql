
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
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
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId
)

SELECT 
    U.DisplayName,
    UV.VoteCount,
    UV.UpVoteCount,
    UV.DownVoteCount,
    PS.PostId,
    PS.Title,
    PS.PostTypeId,
    PS.CommentCount,
    PS.TotalScore,
    PS.TotalViews
FROM 
    UserVoteCounts UV
JOIN 
    PostStatistics PS ON PS.PostId = (SELECT P.Id FROM Posts P ORDER BY P.Score DESC LIMIT 1)
JOIN 
    Users U ON U.Id = UV.UserId
ORDER BY 
    PS.TotalScore DESC;
