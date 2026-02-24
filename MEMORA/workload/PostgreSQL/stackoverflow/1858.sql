WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        COALESCE(NULLIF(MAX(P.CreationDate), '1970-01-01'), cast('2024-10-01 12:34:56' as timestamp)) AS LastActive
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
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
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.CommentCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC) AS Rank
    FROM 
        UserActivity UA
    LEFT JOIN 
        UserBadges UB ON UA.UserId = UB.UserId
    WHERE 
        UA.Reputation > 100
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    CommentCount,
    COALESCE(GoldBadges, 0) AS GoldBadges,
    COALESCE(SilverBadges, 0) AS SilverBadges,
    COALESCE(BronzeBadges, 0) AS BronzeBadges,
    Rank,
    CASE 
        WHEN Rank <= 10 THEN 'Top User'
        WHEN Rank <= 50 THEN 'Active User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    TopUsers
WHERE 
    (GoldBadges > 0 OR SilverBadges > 0 OR BronzeBadges > 0)
ORDER BY 
    Rank;