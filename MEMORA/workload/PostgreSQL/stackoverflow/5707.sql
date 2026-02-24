WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN a.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        SUM(COALESCE(vs.UpvoteCount, 0)) AS TotalUpvotes,
        SUM(COALESCE(vs.DownvoteCount, 0)) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        UserVoteStats vs ON p.OwnerUserId = vs.UserId
    WHERE 
        p.CreationDate >= '2021-01-01'
    GROUP BY 
        p.Id, p.Title
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.AnswerCount) AS TotalAnswers,
        SUM(ps.TotalUpvotes) AS TotalUpvotes,
        SUM(ps.TotalDownvotes) AS TotalDownvotes
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostStats ps ON ps.PostId = p.Id
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    ts.TagId,
    ts.TagName,
    ts.TotalComments,
    ts.TotalAnswers,
    ts.TotalUpvotes,
    ts.TotalDownvotes,
    (ts.TotalUpvotes - ts.TotalDownvotes) AS NetScore
FROM 
    TagStats ts
WHERE 
    ts.TotalAnswers > 0
ORDER BY 
    NetScore DESC
LIMIT 10;
