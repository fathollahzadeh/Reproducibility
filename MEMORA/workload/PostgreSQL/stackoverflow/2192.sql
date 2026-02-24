WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) as RankByUser
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
        AND P.ViewCount > 100
),
TopPosts AS (
    SELECT 
        R.Id,
        R.Title,
        R.ViewCount,
        R.CreationDate,
        R.Score,
        R.AnswerCount
    FROM 
        RankedPosts R
    WHERE 
        R.RankByUser = 1
),
UserScores AS (
    SELECT 
        U.Id AS UserId,
        (SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetScore
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    COALESCE(US.NetScore, 0) AS NetScore,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    TP.Title,
    TP.ViewCount,
    TP.CreationDate
FROM 
    Users U
LEFT JOIN 
    UserScores US ON U.Id = US.UserId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
RIGHT JOIN 
    TopPosts TP ON U.Id = TP.Id
WHERE 
    U.Reputation > 500
ORDER BY 
    NetScore DESC, TP.ViewCount DESC;
