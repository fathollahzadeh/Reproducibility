WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostsWithComments AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.PostCount,
    UR.QuestionCount,
    UR.AnswerCount,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(PC.TotalViewCount, 0) AS TotalViewCount
FROM 
    UserReputation UR
LEFT JOIN 
    UserBadges UB ON UR.UserId = UB.UserId
LEFT JOIN 
    PostsWithComments PC ON UR.UserId = PC.OwnerUserId
ORDER BY 
    UR.Reputation DESC, UR.PostCount DESC;
