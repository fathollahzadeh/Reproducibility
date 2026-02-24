WITH RankedTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS TagRank
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopUserActivity AS (
    SELECT 
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY 
        u.DisplayName
),
RecentPostEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
),
TagEngagement AS (
    SELECT 
        rt.TagName,
        COUNT(DISTINCT p.Id) AS EngagedPosts,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TagUpvoteCount
    FROM 
        RankedTags rt
    JOIN 
        Posts p ON p.Tags LIKE '%' || rt.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        rt.TagRank <= 10 
    GROUP BY 
        rt.TagName
)
SELECT 
    u.DisplayName,
    ua.AnswerCount,
    ua.UpvoteCount,
    ua.DownvoteCount,
    te.TagName,
    te.EngagedPosts,
    te.CommentCount,
    te.TagUpvoteCount
FROM 
    TopUserActivity ua
JOIN 
    TagEngagement te ON te.TagName IN (SELECT TagName FROM RankedTags WHERE TagRank <= 10)
JOIN 
    Users u ON u.DisplayName = ua.DisplayName
WHERE 
    ua.UserRank <= 5 
ORDER BY 
    ua.AnswerCount DESC, te.EngagedPosts DESC;