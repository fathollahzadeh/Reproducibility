WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS Rank
    FROM
        Posts P
)

SELECT
    U.DisplayName,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RPC.ViewCount
FROM
    Users U
LEFT JOIN (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount
    FROM
        Badges
    GROUP BY
        UserId
) B ON U.Id = B.UserId
LEFT JOIN RankedPosts RP ON U.Id = RP.OwnerUserId AND RP.Rank <= 3
LEFT JOIN (
    SELECT 
        P.OwnerUserId,
        SUM(P.ViewCount) AS ViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
) RPC ON U.Id = RPC.OwnerUserId
WHERE
    RP.PostId IS NOT NULL
    AND (U.Reputation > 1000 OR B.BadgeCount > 0)
    AND NOT EXISTS (
        SELECT 1
        FROM Votes V
        WHERE V.PostId = RP.PostId 
        AND V.VoteTypeId IN (2, 3) 
        GROUP BY V.PostId
        HAVING COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) < COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END)
    )
ORDER BY 
    U.DisplayName,
    RP.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;