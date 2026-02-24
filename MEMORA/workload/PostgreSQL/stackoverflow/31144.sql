WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date AS AwardDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        DENSE_RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewRank,
        MAX(Ph.CreationDate) AS LastUpdateDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory Ph ON P.Id = Ph.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CommentCount,
        AnswerCount,
        Score,
        LastUpdateDate,
        CTE1.BadgeName
    FROM 
        PostAnalytics P
    LEFT JOIN 
        UserBadges CTE1 ON CTE1.BadgeName IN ('Gold', 'Silver') AND P.ScoreRank <= 5
    WHERE 
        P.ViewCount > 100
)
SELECT 
    U.DisplayName,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    COUNT(DISTINCT TP.PostId) AS PostCount,
    AVG(TP.ViewCount) AS AvgViews,
    SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    MAX(TP.LastUpdateDate) AS LatestPostUpdate
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    TopPosts TP ON TP.BadgeName IS NOT NULL
WHERE 
    U.Reputation > 5000
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    AVG(TP.ViewCount) > 50;
