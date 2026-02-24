WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY t.TagName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        p.Body,
        ph.UserDisplayName,
        ph.CreationDate,
        p.Tags,
        ph.Comment,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    GROUP BY ph.PostId, p.Title, p.Body, ph.UserDisplayName, ph.CreationDate, p.Tags, ph.Comment
)
SELECT 
    ua.DisplayName AS User,
    ua.Reputation AS Reputation,
    ua.PostCount AS PostsCreated,
    ua.CommentCount AS CommentsMade,
    ua.TotalBounties AS BountiesReceived,
    ua.TotalUpvotes AS UpvotesGiven,
    ua.TotalDownvotes AS DownvotesGiven,
    ts.TagName AS PopularTag,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews,
    ts.AverageScore AS TagAverageScore,
    phd.Title AS RecentPostTitle,
    phd.Body AS RecentPostBody,
    phd.UserDisplayName AS PostEditor,
    phd.CreationDate AS PostHistoryDate,
    phd.Tags AS PostTags,
    phd.Comment AS PostEditComment,
    phd.CloseVoteCount AS TotalCloseVotes
FROM UserActivity ua
JOIN TagStatistics ts ON ua.PostCount > 0
JOIN PostHistoryDetails phd ON ua.UserId = phd.PostId
WHERE ua.Reputation > 1000
ORDER BY ua.Reputation DESC, ts.PostCount DESC
LIMIT 50;