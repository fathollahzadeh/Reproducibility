
WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS tag,
        COUNT(*) AS total_posts
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        tag
), BadgeStats AS (
    SELECT 
        U.Id AS user_id,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS gold_badges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS silver_badges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS bronze_badges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
), PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS close_count,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS reopen_count,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS delete_count
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.Id AS user_id,
    U.DisplayName,
    COALESCE(TC.total_posts, 0) AS post_count,
    COALESCE(BS.gold_badges, 0) AS gold_badges,
    COALESCE(BS.silver_badges, 0) AS silver_badges,
    COALESCE(BS.bronze_badges, 0) AS bronze_badges,
    COALESCE(PA.close_count, 0) AS close_count,
    COALESCE(PA.reopen_count, 0) AS reopen_count,
    COALESCE(PA.delete_count, 0) AS delete_count,
    STRING_AGG(DISTINCT TC.tag, ', ') AS popular_tags
FROM 
    Users U
LEFT JOIN 
    TagCounts TC ON TC.tag IN (SELECT tag FROM TagCounts ORDER BY total_posts DESC LIMIT 5)
LEFT JOIN 
    BadgeStats BS ON U.Id = BS.user_id
LEFT JOIN 
    PostActivity PA ON U.Id = PA.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, TC.total_posts, BS.gold_badges, BS.silver_badges, BS.bronze_badges, PA.close_count, PA.reopen_count, PA.delete_count
ORDER BY 
    post_count DESC, gold_badges DESC, silver_badges DESC, bronze_badges DESC;
