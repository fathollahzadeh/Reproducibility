WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) A ON P.Id = A.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS Count
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
FinalResults AS (
    SELECT 
        PI.PostId,
        PI.Title,
        PI.CreationDate,
        PI.ViewCount,
        PI.Score,
        PI.AnswerCount,
        PI.CommentCount,
        PI.OwnerDisplayName,
        UB.UserId,
        UB.DisplayName AS UserDisplayName,
        UB.BadgeCount,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        PH.PostHistoryTypeId,
        PH.Count AS HistoryCount
    FROM 
        PostInfo PI
    LEFT JOIN 
        UserBadges UB ON PI.OwnerDisplayName = UB.DisplayName
    LEFT JOIN 
        PostHistoryInfo PH ON PI.PostId = PH.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    UserId,
    UserDisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostHistoryTypeId,
    HistoryCount
FROM 
    FinalResults
ORDER BY 
    CreationDate DESC
LIMIT 100;