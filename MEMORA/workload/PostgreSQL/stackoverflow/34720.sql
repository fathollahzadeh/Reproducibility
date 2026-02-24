
WITH RankedPostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
UserActivity AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN C.CreationDate > CURRENT_DATE - INTERVAL '6 months' THEN 1 ELSE 0 END) AS RecentComments
    FROM 
        Comments C
    GROUP BY 
        C.UserId
),
PostDetails AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ScoreRank,
        U.Reputation,
        COALESCE(UA.CommentCount, 0) AS CommentCount,
        COALESCE(UA.RecentComments, 0) AS RecentComments,
        CASE WHEN PS.ScoreRank = 1 THEN 'Top' ELSE 'Others' END AS PostCategory
    FROM 
        RankedPostScores PS
    JOIN 
        Posts P ON P.Id = PS.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UserActivity UA ON U.Id = UA.UserId
)
SELECT 
    PD.Title,
    PD.ScoreRank,
    PD.Reputation AS UserReputation,
    PD.CommentCount,
    PD.RecentComments,
    PD.PostCategory,
    CASE 
        WHEN PD.Reputation > 1000 THEN 'High Reputation User'
        WHEN PD.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation User'
        ELSE 'Low Reputation User'
    END AS ReputationCategory
FROM 
    PostDetails PD
WHERE 
    PD.ScoreRank <= 10 
ORDER BY 
    PD.ScoreRank;
