
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        AnswerCount, 
        QuestionCount, 
        Upvotes, 
        Downvotes, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges
    FROM 
        UserActivity
    ORDER BY 
        PostCount DESC 
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.AnswerCount,
    U.QuestionCount,
    U.Upvotes,
    U.Downvotes,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    COALESCE(ROUND((CAST(U.Upvotes AS FLOAT) / NULLIF(U.PostCount, 0)) * 100, 2), 0) AS UpvotePercentage
FROM 
    TopUsers U
ORDER BY 
    U.PostCount DESC;
