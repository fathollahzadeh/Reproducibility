WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.Id) > 5
),
PostHistoryWithComments AS (
    SELECT 
        ph.Id AS HistoryId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        COUNT(c.Id) AS CommentCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        ph.Id, p.Title, ph.CreationDate, ph.UserDisplayName, ph.Comment
)
SELECT 
    u.DisplayName,
    u.TotalUpvotes,
    u.TotalDownvotes,
    u.TotalPosts,
    u.TotalComments,
    t.TagName,
    t.TagPostCount,
    ph.Title,
    ph.CreationDate,
    ph.UserDisplayName AS EditorUsername,
    ph.Comment,
    ph.CommentCount
FROM 
    UserVoteSummary u
CROSS JOIN 
    PopularTags t
JOIN 
    PostHistoryWithComments ph ON 
        ph.UserDisplayName = u.DisplayName
ORDER BY 
    u.TotalUpvotes DESC, 
    t.TagPostCount DESC, 
    ph.CreationDate DESC
LIMIT 100;
