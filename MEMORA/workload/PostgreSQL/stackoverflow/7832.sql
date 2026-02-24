
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        T.TagName,
        SUM(COALESCE(P.ViewCount, 0)) AS TagTotalViews,
        COUNT(DISTINCT P.Id) AS TagPostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    ORDER BY TagTotalViews DESC
    LIMIT 5
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        P.Title
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 month'
    ORDER BY PH.CreationDate DESC
    LIMIT 10
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalScore,
    US.TotalViews,
    TT.TagName,
    TT.TagTotalViews,
    TT.TagPostCount,
    RE.PostId AS RecentEditPostId,
    RE.Title AS RecentEditTitle,
    RE.CreationDate AS RecentEditDate,
    RE.Comment AS RecentEditComment
FROM UserStats US
LEFT JOIN TopTags TT ON TRUE
LEFT JOIN RecentEdits RE ON RE.UserId = US.UserId
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, TT.TagTotalViews DESC, RE.CreationDate DESC;
