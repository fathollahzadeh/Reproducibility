
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        P.OwnerUserId,
        U.Reputation
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId, U.Reputation
),
UserStats AS (
    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.BadgeCount,
    PS.VoteCount,
    US.DisplayName AS OwnerDisplayName,
    US.Reputation AS OwnerReputation,
    US.PostCount AS OwnerPostCount,
    US.TotalScore AS OwnerTotalScore,
    US.TotalViews AS OwnerTotalViews
FROM 
    PostStatistics PS
JOIN 
    UserStats US ON PS.OwnerUserId = US.Id
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
