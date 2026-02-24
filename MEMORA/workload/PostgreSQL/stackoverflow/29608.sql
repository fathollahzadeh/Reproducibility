
WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Users.Reputation) AS AvgUserReputation
    FROM 
        Tags
    JOIN 
        Posts ON Tags.ExcerptPostId = Posts.Id
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT
        Users.DisplayName,
        COUNT(Posts.Id) AS PostsMade,
        SUM(Comments.Score) AS TotalCommentScore,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users 
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId 
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId 
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId 
    GROUP BY 
        Users.DisplayName
),
RecentPostEdits AS (
    SELECT 
        Posts.Title,
        Posts.Body,
        PostHistory.CreationDate AS EditDate,
        PostHistory.UserDisplayName AS Editor,
        PostHistory.Comment AS EditComment
    FROM 
        PostHistory
    JOIN 
        Posts ON PostHistory.PostId = Posts.Id
    WHERE 
        PostHistory.PostHistoryTypeId IN (4, 5) 
        AND PostHistory.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgUserReputation,
    ua.DisplayName AS User,
    ua.PostsMade,
    ua.TotalCommentScore,
    ua.UpvotesReceived,
    ua.DownvotesReceived,
    rpe.Title AS RecentEditedPostTitle,
    rpe.EditDate,
    rpe.Editor,
    rpe.EditComment
FROM 
    TagStats AS ts
JOIN 
    UserActivity AS ua ON ts.AvgUserReputation > 1000 
LEFT JOIN 
    RecentPostEdits AS rpe ON rpe.EditDate = (SELECT MAX(EditDate) FROM RecentPostEdits) 
ORDER BY 
    ts.PostCount DESC, ts.TotalViews DESC, ua.PostsMade DESC;
