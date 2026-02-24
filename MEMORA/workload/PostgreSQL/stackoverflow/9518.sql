WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
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
        U.Reputation,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    HAVING 
        COUNT(P.Id) >= 5
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    TU.DisplayName AS UserName,
    TU.Reputation,
    TU.PostCount,
    R.Title AS TopPostTitle,
    R.CreationDate AS TopPostDate,
    R.Score AS TopPostScore,
    UB.BadgeNames
FROM 
    TopUsers TU
LEFT JOIN 
    RankedPosts R ON TU.UserId = R.PostId
LEFT JOIN 
    UserBadges UB ON TU.UserId = UB.UserId
WHERE 
    R.PostRank = 1
ORDER BY 
    TU.Reputation DESC, TU.PostCount DESC;
