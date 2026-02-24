WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        B.Name AS BadgeName, 
        B.Class, 
        COUNT(*) OVER (PARTITION BY U.Id) AS BadgeCount
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        BadgeCount,
        RANK() OVER (ORDER BY BadgeCount DESC) AS Rank
    FROM 
        UserBadges
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    SUM(CASE WHEN P.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
    SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostsWithComments,
    T.TagName,
    COUNT(DISTINCT PT.Id) AS TotalPostTypes,
    MAX(T2.CreationDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, '>')) AS TagName
    ) T ON TRUE
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    Posts P2 ON P.AcceptedAnswerId = P2.Id
LEFT JOIN 
    (
        SELECT 
            PostId, 
            MAX(CreationDate) AS CreationDate 
        FROM 
            PostLinks 
        GROUP BY 
            PostId
    ) T2 ON P.Id = T2.PostId
GROUP BY 
    U.Id, U.DisplayName, T.TagName
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    TotalPosts DESC, UserId
LIMIT 
    50;
