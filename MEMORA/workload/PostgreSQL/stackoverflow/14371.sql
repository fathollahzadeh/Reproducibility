WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 END) AS HistoryCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(U.Reputation) AS TotalReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.CommentCount,
    PS.VoteCount,
    PS.HistoryCount,
    PS.TotalScore,
    PS.TotalViews,
    US.UserId,
    US.PostCount,
    US.TotalReputation
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostTypeId = 1 AND U.Id = PS.PostId  
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.TotalViews DESC;