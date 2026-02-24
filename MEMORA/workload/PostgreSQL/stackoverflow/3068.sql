
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.CommentCount,
        us.UpVoteCount,
        us.DownVoteCount 
    FROM UserStats us
    WHERE us.UserRank <= 10
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.AvgScore, 0) AS AvgScore,
    COALESCE(ps.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    CASE 
        WHEN tu.UpVoteCount > tu.DownVoteCount THEN 'More Upvotes'
        WHEN tu.UpVoteCount < tu.DownVoteCount THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteSummary
FROM TopUsers tu
LEFT JOIN PostStatistics ps ON tu.UserId = ps.OwnerUserId
ORDER BY tu.Reputation DESC, tu.DisplayName;
