WITH UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        MAX(u.LastAccessDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(t.Count) AS TotalTagCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    us.DisplayName AS UserName,
    us.Reputation AS UserReputation,
    us.PostCount AS TotalPosts,
    us.CommentCount AS TotalComments,
    ps.PostId AS FeaturedPostId,
    ps.Title AS FeaturedPostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.Score AS PostScore,
    ps.ViewCount AS PostViewCount,
    ts.TagName AS PopularTag,
    ts.PostCount AS TagPostCount,
    ts.TotalTagCount AS OverallTagCount
FROM 
    UserSummary us
JOIN 
    PostSummary ps ON us.UserId = ps.PostId
JOIN 
    TagSummary ts ON ts.PostCount > 5
WHERE 
    us.LastActiveDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
ORDER BY 
    us.Reputation DESC, ps.Score DESC, ts.TotalTagCount DESC
LIMIT 10;