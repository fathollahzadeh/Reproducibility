
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        MAX(P.Score) AS HighestScore,
        MIN(P.CreationDate) AS EarliestPost
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 0
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        HighestScore,
        EarliestPost,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        UserPostStats
),

HighScorePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        CASE 
            WHEN P.Score > 0 THEN 'Positive'
            WHEN P.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreType,
        ARRAY_AGG(T.TagName) AS PostTags
    FROM 
        Posts AS P
    JOIN 
        Users AS U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UNNEST(string_to_array(P.Tags, ',')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags AS T ON T.TagName = TRIM(tag_name)
    WHERE 
        P.Score IS NOT NULL
    GROUP BY 
        P.Id, U.DisplayName
    ORDER BY 
        P.Score DESC
),

PostHistoryWithComments AS (
    SELECT 
        PH.Id AS HistoryId,
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        PH.Text AS HistoryText,
        C.Text AS CommentText,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CommentRank
    FROM 
        PostHistory AS PH
    LEFT JOIN 
        Comments AS C ON PH.PostId = C.PostId AND PH.CreationDate < C.CreationDate
    WHERE 
        PH.PostHistoryTypeId NOT IN (12, 13) 
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    COALESCE(TU.TotalPosts, 0) AS TotalPosts,
    COALESCE(TU.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(TU.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(TU.TotalViews, 0) AS TotalViews,
    (SELECT COUNT(*) FROM HighScorePosts WHERE OwnerName = U.DisplayName AND Score > 0) AS PositivePostCount,
    (SELECT COUNT(*) FROM HighScorePosts WHERE OwnerName = U.DisplayName AND Score < 0) AS NegativePostCount,
    ARRAY_AGG(DISTINCT PH.Comment) AS RecentComments
FROM 
    Users AS U
LEFT JOIN 
    TopUsers AS TU ON U.Id = TU.UserId
LEFT JOIN 
    PostHistoryWithComments AS PH ON U.Id = PH.UserId
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.DisplayName, U.Reputation, TU.TotalPosts, TU.TotalQuestions, TU.TotalAnswers, TU.TotalViews
ORDER BY 
    U.Reputation DESC,
    COALESCE(TU.TotalPosts, 0) DESC;
