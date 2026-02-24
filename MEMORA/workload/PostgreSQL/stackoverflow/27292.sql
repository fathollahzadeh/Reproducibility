WITH UserRank AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(P.AcceptedAnswerId IS NOT NULL, FALSE) AS IsAccepted,
        T.TagName,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        UNNEST(string_to_array(P.Tags, '>')) AS T(TagName) ON TRUE
    WHERE 
        P.PostTypeId = 1 
),
MostActiveUsers AS (
    SELECT 
        PostSummary.OwnerDisplayName,
        COUNT(PostSummary.PostId) AS QuestionCount,
        SUM(PostSummary.ViewCount) AS TotalViews,
        SUM(PostSummary.AnswerCount) AS TotalAnswers,
        R.UserRank
    FROM 
        PostSummary
    JOIN 
        UserRank R ON PostSummary.OwnerDisplayName = R.DisplayName
    GROUP BY 
        PostSummary.OwnerDisplayName, R.UserRank
),
TopActiveUsers AS (
    SELECT 
        OwnerDisplayName,
        QuestionCount,
        TotalViews,
        TotalAnswers,
        RANK() OVER (ORDER BY QuestionCount DESC, TotalViews DESC) AS ActivityRank
    FROM 
        MostActiveUsers
)
SELECT 
    OwnerDisplayName,
    QuestionCount,
    TotalViews,
    TotalAnswers,
    ActivityRank
FROM 
    TopActiveUsers
WHERE 
    ActivityRank <= 10
ORDER BY 
    ActivityRank;