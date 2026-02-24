
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
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
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.ViewCount DESC
    LIMIT 10
),
RecentActivity AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.LastActivityDate,
        PT.Name AS PostType
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
    ORDER BY 
        PH.CreationDate DESC
    LIMIT 5
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PP.PostId,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.ViewCount AS PopularPostViewCount,
    PP.AnswerCount AS PopularPostAnswerCount,
    PP.CommentCount AS PopularPostCommentCount,
    RA.PostId AS RecentActivityPostId,
    RA.CreationDate AS RecentActivityDate,
    RA.Title AS RecentActivityPostTitle,
    RA.PostType AS RecentActivityPostType
FROM 
    UserBadges UB
LEFT JOIN 
    PopularPosts PP ON UB.DisplayName = PP.OwnerDisplayName
LEFT JOIN 
    RecentActivity RA ON UB.UserId = RA.UserId
WHERE 
    UB.GoldBadges > 0 OR UB.SilverBadges > 0 OR UB.BronzeBadges > 0
ORDER BY 
    UB.UserId, PP.ViewCount DESC, RA.CreationDate DESC;
