WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(VB.BountyAmount, 0)) AS TotalBountyAwarded
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId IN (8, 9) 
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate, U.Views
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        LastAccessDate,
        Views, 
        PostCount,
        TotalBountyAwarded,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserActivity
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.CreationDate,
    TU.LastAccessDate,
    TU.Views,
    TU.PostCount,
    TU.TotalBountyAwarded,
    COALESCE(PS.CommentCount, 0) AS CommentCount,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    PS.LastPostDate
FROM 
    TopUsers TU
LEFT JOIN 
    PostStatistics PS ON TU.UserId = PS.OwnerUserId
WHERE 
    TU.Rank <= 10 
ORDER BY 
    TU.Rank;