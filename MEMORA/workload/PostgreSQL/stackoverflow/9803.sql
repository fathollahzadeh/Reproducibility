WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, BadgeCount DESC) AS Rank
    FROM 
        Users U
    JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    WHERE 
        U.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        ROW_NUMBER() OVER (ORDER BY P.ViewCount DESC, P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND P.PostTypeId = 1
),
CombinedData AS (
    SELECT 
        TU.DisplayName,
        TU.Reputation,
        TU.GoldBadges,
        TU.SilverBadges,
        TU.BronzeBadges,
        PP.Title,
        PP.Score,
        PP.ViewCount,
        PP.AnswerCount,
        PP.CommentCount,
        PP.CreationDate
    FROM 
        TopUsers TU
    JOIN 
        PopularPosts PP ON TU.Rank <= 10
)
SELECT 
    DisplayName,
    Reputation,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Title,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    CreationDate
FROM 
    CombinedData
ORDER BY 
    Reputation DESC, Score DESC;