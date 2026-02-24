WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id), 0) AS VoteCount,
        P.CreationDate,
        P.LastActivityDate
    FROM 
        Posts P
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
Summary AS (
    SELECT 
        P.PostTypeId,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViewCount,
        SUM(P.CommentCount) AS TotalComments,
        SUM(P.VoteCount) AS TotalVotes,
        COUNT(DISTINCT P.PostId) AS NumberOfPosts
    FROM 
        PostStats P
    GROUP BY 
        P.PostTypeId
)
SELECT 
    S.PostTypeId,
    S.AvgScore,
    S.AvgViewCount,
    S.TotalComments,
    S.TotalVotes,
    U.PostCount AS TotalUsers,
    U.TotalUpVotes,
    U.TotalDownVotes
FROM 
    Summary S
JOIN 
    UserStats U ON U.PostCount > 0
ORDER BY 
    S.PostTypeId;