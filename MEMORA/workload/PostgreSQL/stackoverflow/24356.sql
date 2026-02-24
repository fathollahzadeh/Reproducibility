
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenActivity,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesGiven,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesGiven
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
BizarreStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT CASE WHEN B.Class = 1 THEN B.Id END) AS GoldBadges,
        COUNT(DISTINCT CASE WHEN B.Class = 2 THEN B.Id END) AS SilverBadges,
        COUNT(DISTINCT CASE WHEN B.Class = 3 THEN B.Id END) AS BronzeBadges,
        COUNT(DISTINCT CASE WHEN P.Score < 0 THEN P.Id END) AS NegativeScoredPosts,
        (SELECT COUNT(*) FROM Posts P2 WHERE P2.OwnerUserId = U.Id AND P2.CreationDate > U.CreationDate) AS PostsSinceJoin
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    R.Title AS LatestQuestionTitle,
    UA.CloseOpenActivity,
    UA.UpvotesGiven,
    UA.DownvotesGiven,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges,
    BS.NegativeScoredPosts,
    BS.PostsSinceJoin
FROM 
    Users U
LEFT JOIN 
    RankedPosts R ON U.Id = R.OwnerUserId AND R.RN = 1
LEFT JOIN 
    UserActivity UA ON U.Id = UA.UserId
LEFT JOIN 
    BizarreStats BS ON U.Id = BS.UserId
WHERE 
    BS.NegativeScoredPosts > 5
    OR (BS.GoldBadges > 0 AND UA.UpvotesGiven = 0)
ORDER BY 
    COALESCE(UA.UpvotesGiven, 0) DESC, 
    COALESCE(UA.DownvotesGiven, 0) ASC;
