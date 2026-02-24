WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  
    WHERE u.Reputation > 50  
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus,
        COALESCE(SUM(c.Score), 0) AS CommentScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE
    GROUP BY p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId
),
Benchmarking AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Tags,
        pd.AnswerStatus,
        pd.CommentScore,
        ua.TotalViews,
        ua.TotalBounties
    FROM UserActivity ua
    JOIN PostDetails pd ON ua.UserId = pd.PostId
    WHERE ua.ViewRank <= 10  
)

SELECT 
    b.UserId,
    b.DisplayName,
    COUNT(b.PostId) AS TotalPosts,
    SUM(b.CommentScore) AS TotalCommentScore,
    AVG(b.TotalViews) AS AvgViewsPerPost,
    MAX(b.TotalBounties) AS HighestBounty
FROM Benchmarking b
GROUP BY b.UserId, b.DisplayName
ORDER BY AVG(b.TotalViews) DESC, COUNT(b.PostId) DESC
LIMIT 5;