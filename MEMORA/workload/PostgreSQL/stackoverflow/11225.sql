WITH PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PVS.PostId,
    PVS.Title,
    PVS.PostTypeId,
    PVS.VoteCount,
    PVS.UpVoteCount,
    PVS.DownVoteCount,
    US.UserId,
    US.DisplayName,
    US.BadgeCount,
    US.TotalViews,
    US.TotalScore
FROM 
    PostVoteStats PVS
JOIN 
    Users U ON PVS.PostId = U.AccountId
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PVS.VoteCount DESC, US.TotalScore DESC;
