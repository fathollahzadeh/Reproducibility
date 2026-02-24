
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesCount,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS EngagementRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostsCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.*,
        ph.CreationDate AS LastEditedDate,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
    GROUP BY 
        p.Id, ph.CreationDate
)
SELECT 
    ue.DisplayName,
    ue.PostsCount,
    ue.QuestionsCount,
    ue.AnswersCount,
    ue.CommentsCount,
    ue.UpvotesCount,
    ue.DownvotesCount,
    tt.TagName AS PopularTag,
    ps.Title,
    ps.LastEditedDate,
    ps.TotalComments,
    ps.TotalVotes
FROM 
    UserEngagement ue
CROSS JOIN 
    TopTags tt
JOIN 
    PostStatistics ps ON ue.UserId = ps.OwnerUserId
WHERE 
    ue.EngagementRank <= 5
ORDER BY 
    ue.EngagementRank, ps.TotalVotes DESC;
