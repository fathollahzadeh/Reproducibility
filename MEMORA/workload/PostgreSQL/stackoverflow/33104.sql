WITH RECURSIVE UserPostCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UPC.PostCount, 0) AS PostCount,
        COALESCE(UPC.TotalScore, 0) AS TotalScore,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.HighestBadgeClass, 0) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        UserPostCount UPC ON U.Id = UPC.UserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    WHERE 
        U.Reputation > 1000
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        P.OwnerUserId
),
FinalStatistics AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TU.Reputation,
        TU.PostCount,
        TU.TotalScore,
        TU.BadgeCount,
        TU.HighestBadgeClass,
        COALESCE(PS.CommentCount, 0) AS TotalComments,
        COALESCE(PS.TotalBounties, 0) AS TotalBounties
    FROM 
        TopUsers TU
    LEFT JOIN 
        PostStatistics PS ON TU.UserId = PS.OwnerUserId
)
SELECT 
    F.UserId,
    F.DisplayName,
    F.Reputation,
    F.PostCount,
    F.TotalScore,
    F.BadgeCount,
    F.HighestBadgeClass,
    F.TotalComments,
    F.TotalBounties
FROM 
    FinalStatistics F
WHERE 
    F.TotalBounties > 0 OR F.TotalComments > 10
ORDER BY 
    F.Reputation DESC, 
    F.TotalScore DESC;