
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year' AND 
        P.Score >= 10
), RecentBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Date >= CURRENT_TIMESTAMP - INTERVAL '6 months'
    GROUP BY 
        B.UserId
), ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        R.BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        RecentBadges R ON U.Id = R.UserId
    WHERE 
        U.LastAccessDate >= CURRENT_TIMESTAMP - INTERVAL '3 months'
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.Score,
    RP.ViewCount,
    RP.CreationDate,
    AU.DisplayName AS ActiveUser,
    AU.Reputation,
    AU.BadgeCount
FROM 
    RankedPosts RP
JOIN 
    ActiveUsers AU ON RP.OwnerDisplayName = AU.DisplayName
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
