
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        COALESCE(SUM(UP.VoteCount), 0) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        (
            SELECT 
                P.OwnerUserId,
                P.Id,
                P.Score,
                COUNT(V.Id) AS VoteCount
            FROM 
                Posts P
            LEFT JOIN 
                Votes V ON V.PostId = P.Id
            WHERE 
                P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
            GROUP BY 
                P.OwnerUserId, P.Id
        ) UP ON UP.OwnerUserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), PostsRanked AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.PositivePostCount,
    UA.NegativePostCount,
    UA.TotalVotes,
    UB.BadgeCount,
    UB.BadgeNames,
    P.PostId,
    P.Title,
    P.Score,
    P.PostRank
FROM 
    UserActivity UA
LEFT JOIN 
    UserBadges UB ON UA.UserId = UB.UserId
LEFT JOIN 
    PostsRanked P ON UA.UserId = P.OwnerUserId AND P.PostRank <= 3  
WHERE 
    UA.PostCount > 10
ORDER BY 
    UA.TotalVotes DESC, 
    UA.PostCount DESC;
