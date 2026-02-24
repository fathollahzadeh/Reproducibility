WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END, 0)) AS CommentCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS Upvotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS Downvotes,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalScore,
    UA.CommentCount,
    UA.Upvotes,
    UA.Downvotes,
    B.BadgeCount,
    B.GoldBadges,
    B.SilverBadges,
    B.BronzeBadges,
    UA.LastPostDate
FROM 
    UserActivity UA
LEFT JOIN 
    BadgeCounts B ON UA.UserId = B.UserId
WHERE 
    UA.PostCount > 0
ORDER BY 
    UA.TotalScore DESC, UA.LastPostDate DESC
LIMIT 100;
