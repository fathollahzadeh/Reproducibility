
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) OVER (PARTITION BY P.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    UP.BadgeCount,
    UP.GoldBadge,
    UP.SilverBadge,
    UP.BronzeBadge,
    PP.PostId,
    PP.Title,
    PP.ViewCount,
    PP.Score,
    PV.UpVotes,
    PV.DownVotes,
    PP.CommentCount,
    PP.CreationDate,
    CASE 
        WHEN PV.UpVotes > PV.DownVotes THEN 'Positive' 
        ELSE 'Negative' 
    END AS Sentiment,
    CASE 
        WHEN PP.CreationDate < (SELECT MIN(CreationDate) FROM Posts WHERE Score >= 1) THEN 'Legacy Post' 
        ELSE 'Recent Post' 
    END AS PostType
FROM 
    RankedPosts PP
JOIN 
    Users U ON PP.PostId = (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id AND P.PostTypeId = 1 ORDER BY P.CreationDate DESC LIMIT 1)
JOIN 
    UserBadges UP ON U.Id = UP.UserId
LEFT JOIN 
    PostVotes PV ON PP.PostId = PV.PostId
WHERE 
    PP.ScoreRank <= 5
ORDER BY 
    PP.Score DESC, PP.CommentCount DESC;
