WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),

QuestionPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.ViewCount,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        ARRAY_TO_STRING(STRING_TO_ARRAY(P.Tags, '>'), ', ') AS TagsArray
    FROM Posts P
    WHERE P.PostTypeId = 1
),

PopularQuestions AS (
    SELECT 
        Q.*, 
        RANK() OVER (ORDER BY Q.ViewCount DESC) AS ViewRank
    FROM QuestionPosts Q
    WHERE Q.ViewCount > 100 AND Q.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),

AnswersWithComments AS (
    SELECT 
        A.Id AS AnswerId,
        A.OwnerUserId,
        A.ParentId,
        C.UserId AS CommenterId,
        COUNT(C.Id) AS CommentCount
    FROM Posts A
    LEFT JOIN Comments C ON A.Id = C.PostId
    WHERE A.PostTypeId = 2
    GROUP BY A.Id, A.OwnerUserId, A.ParentId, C.UserId
),

BenchmarkStats AS (
    SELECT 
        U.UserId,
        U.BadgeCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        PQ.PostId,
        PQ.Title,
        PQ.ViewCount,
        COALESCE(AC.CommentCount, 0) AS AnswerCommentCount
    FROM UserBadges U
    JOIN PopularQuestions PQ ON U.UserId = PQ.OwnerUserId
    LEFT JOIN AnswersWithComments AC ON PQ.PostId = AC.ParentId
),

FinalResult AS (
    SELECT 
        UserId, 
        PostId, 
        Title,
        ViewCount,
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        AnswerCommentCount,
        LEAD(ViewCount) OVER (PARTITION BY UserId ORDER BY ViewCount DESC) AS NextViewCount,
        CASE 
            WHEN AnswerCommentCount > 0 THEN 'Active Engagement' 
            ELSE 'Low Engagement' 
        END AS EngagementLevel,
        CASE 
            WHEN BadgeCount > 5 THEN 'High Achiever'
            ELSE 'Novice'
        END AS AchievementLevel
    FROM BenchmarkStats
)

SELECT 
    *,
    CASE 
        WHEN ViewCount > 2000 THEN 'Highly Viewed'
        WHEN ViewCount > 1000 THEN 'Moderately Viewed'
        ELSE 'Low Viewed'
    END AS ViewCategory
FROM FinalResult
WHERE BadgeCount > 0 
ORDER BY ViewCount DESC, UserId ASC;