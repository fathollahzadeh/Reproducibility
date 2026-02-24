WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount    
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id, P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    U.UserId,
    U.PostCount,
    U.TotalScore,
    U.TotalViews,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.BadgeCount
FROM 
    UserStats U
JOIN 
    PostStats PS ON U.UserId = PS.PostId
ORDER BY 
    U.TotalScore DESC, 
    U.PostCount DESC;