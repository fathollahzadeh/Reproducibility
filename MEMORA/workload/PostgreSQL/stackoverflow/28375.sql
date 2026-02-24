
WITH TagCount AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers,
        AVG(Users.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS ActiveUsers
    FROM 
        Posts
    JOIN 
        Tags ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Tags.TagName
),
ClosedPostDetails AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        PostHistory.CreationDate AS CloseDate,
        CloseReasonTypes.Name AS CloseReason
    FROM 
        Posts
    JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    JOIN 
        CloseReasonTypes ON CAST(PostHistory.Comment AS INTEGER) = CloseReasonTypes.Id
    WHERE 
        PostHistory.PostHistoryTypeId = 10 
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        AvgReputation,
        ActiveUsers,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCount
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.TotalAnswers,
    T.AvgReputation,
    T.ActiveUsers,
    CP.PostId,
    CP.Title,
    CP.CreationDate,
    CP.CloseDate,
    CP.CloseReason
FROM 
    TopTags T
LEFT JOIN 
    ClosedPostDetails CP ON T.TagName IN (
        SELECT UNNEST(STRING_TO_ARRAY(Posts.Tags, '>')) 
        FROM Posts 
        WHERE Posts.PostTypeId = 1
    )
WHERE 
    T.TagRank <= 10 
ORDER BY 
    T.PostCount DESC, T.TotalViews DESC;
