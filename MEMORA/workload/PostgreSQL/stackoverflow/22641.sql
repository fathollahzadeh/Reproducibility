WITH User_Aggregates AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN PT.Name = 'Question' AND P.Score > 0 THEN 1 ELSE 0 END) AS PositiveQuestions,
        SUM(CASE WHEN PT.Name = 'Answer' AND P.Score < 0 THEN 1 ELSE 0 END) AS NegativeAnswers
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
PostHistory_Summary AS (
    SELECT 
        PH.UserId,
        COUNT(CASE WHEN PHT.Name = 'Post Closed' THEN 1 END) AS ClosedPosts,
        COUNT(CASE WHEN PHT.Name = 'Post Reopened' THEN 1 END) AS ReopenedPosts,
        COUNT(*) AS TotalEdits,
        COUNT(DISTINCT PH.PostId) AS UniquePosts
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId
),
Post_Stats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        COALESCE(MAX(P.CreationDate), '1970-01-01') AS LatestPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
Combined AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.Views,
        UA.BadgeCount,
        PHS.ClosedPosts,
        PHS.ReopenedPosts,
        PS.TotalPosts,
        PS.TotalScore,
        PS.LatestPostDate
    FROM 
        User_Aggregates UA
    LEFT JOIN 
        PostHistory_Summary PHS ON UA.UserId = PHS.UserId
    LEFT JOIN 
        Post_Stats PS ON UA.UserId = PS.OwnerUserId
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.Reputation,
    C.Views,
    C.BadgeCount,
    COALESCE(C.ClosedPosts, 0) AS ClosedPosts,
    COALESCE(C.ReopenedPosts, 0) AS ReopenedPosts,
    COALESCE(C.TotalPosts, 0) AS TotalPosts,
    COALESCE(C.TotalScore, 0) AS TotalScore,
    CASE 
        WHEN C.LatestPostDate IS NOT NULL 
        THEN EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - C.LatestPostDate)) / 86400 
        ELSE NULL 
    END AS DaysSinceLastPost
FROM 
    Combined C
WHERE 
    (C.Reputation > 100 OR C.BadgeCount > 5) 
    AND (C.Views IS NOT NULL OR C.TotalPosts > 5)
ORDER BY 
    C.Reputation DESC, C.Views DESC, C.BadgeCount DESC
LIMIT 50;