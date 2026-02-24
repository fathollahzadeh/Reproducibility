
WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
), UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.QuestionCount,
    U.AnswerCount,
    U.CommentCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PH.EditCount,
    PH.CloseReopenCount,
    PH.DeleteUndeleteCount,
    (SELECT STRING_AGG(T.TagName, ', ' ORDER BY T.TagCount DESC)
     FROM TagStats T
     WHERE T.TagCount > 5) AS PopularTags
FROM 
    UserStats U
LEFT JOIN 
    PostHistoryStats PH ON U.UserId = PH.UserId
ORDER BY 
    U.AnswerCount DESC
LIMIT 10;
