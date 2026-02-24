
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.PostCount,
    US.TotalBounty,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.AverageReputation,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.OwnerDisplayName
FROM 
    UserStats US
LEFT JOIN 
    PostStats PS ON US.UserId = PS.OwnerUserId
ORDER BY 
    US.PostCount DESC, US.TotalBounty DESC;
