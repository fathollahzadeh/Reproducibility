WITH UserProfile AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views, U.UpVotes, U.DownVotes
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS HistoryChanges,
        COUNT(DISTINCT PH.PostId) AS PostsChanged,
        MAX(PH.CreationDate) AS LastActivityDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    UP.UserId,
    UP.DisplayName,
    UP.Reputation,
    UP.Views,
    UP.UpVotes,
    UP.DownVotes,
    UP.TotalPosts,
    UP.TotalAnswers,
    UP.TotalQuestions,
    UP.TotalBadges,
    UTC.TagName,
    UTC.PostCount,
    UA.HistoryChanges,
    UA.PostsChanged,
    UA.LastActivityDate
FROM 
    UserProfile UP
LEFT JOIN 
    UserActivity UA ON UP.UserId = UA.UserId
LEFT JOIN 
    PopularTags UTC ON UA.PostsChanged > 0
ORDER BY 
    UP.Reputation DESC, 
    UP.TotalPosts DESC;
