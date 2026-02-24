WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND P.Score > 0
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(RP.PostId) AS PostCount,
        SUM(RP.Score) AS TotalScore
    FROM 
        RankedPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(RP.PostId) >= 5
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.TotalScore,
    UB.BadgeCount,
    (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = TU.UserId AND P.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswersCount
FROM 
    TopUsers TU
JOIN 
    UserBadges UB ON TU.UserId = UB.UserId
ORDER BY 
    TU.TotalScore DESC, TU.PostCount DESC;
