
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ARRAY_AGG(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        unnest(string_to_array(P.Tags, '><')) AS T(TagName) ON TRUE
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CreationDate,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.Tags,
    UB.UserId,
    UB.GoldBadgeCount,
    UB.SilverBadgeCount,
    UB.BronzeBadgeCount
FROM 
    PostStats PS
JOIN 
    Users U ON U.Id = PS.PostId
JOIN 
    UserBadges UB ON U.Id = UB.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
