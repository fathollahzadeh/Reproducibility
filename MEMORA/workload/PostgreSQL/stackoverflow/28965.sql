WITH RecentQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON ',' || p.Tags || ',' LIKE '%,' || t.TagName || ',%'
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Body
),
UserEngagement AS (
    SELECT 
        q.QuestionId,
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount, 
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount 
    FROM 
        RecentQuestions q
    JOIN 
        Comments c ON q.QuestionId = c.PostId
    JOIN 
        Users u ON u.Id = q.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = q.QuestionId
    GROUP BY 
        q.QuestionId, u.Id, u.DisplayName
),
RankedEngagement AS (
    SELECT 
        ue.QuestionId,
        ue.DisplayName,
        ue.CommentCount,
        ue.UpvoteCount,
        ue.DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY (ue.CommentCount + ue.UpvoteCount - ue.DownvoteCount) DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    rq.QuestionId,
    rq.DisplayName AS QuestionOwner,
    rq.CommentCount,
    rq.UpvoteCount,
    rq.DownvoteCount,
    rq.EngagementRank,
    r.Title,
    r.CreationDate,
    r.Body,
    r.Tags
FROM 
    RankedEngagement rq
JOIN 
    RecentQuestions r ON rq.QuestionId = r.QuestionId
WHERE 
    rq.EngagementRank <= 10 
ORDER BY 
    rq.EngagementRank;