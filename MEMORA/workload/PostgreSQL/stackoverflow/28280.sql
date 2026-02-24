
WITH RecentQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags, u.DisplayName
    HAVING 
        COUNT(a.Id) > 0  
),
TagStats AS (
    SELECT 
        LOWER(TRIM(UNNEST(STRING_TO_ARRAY(p.Tags, '> <')))) AS TagName,
        COUNT(p.Id) AS QuestionCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        LOWER(TRIM(UNNEST(STRING_TO_ARRAY(p.Tags, '> <'))))
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        v.UserId
)
SELECT 
    rq.Title,
    rq.OwnerDisplayName,
    rq.AnswerCount,
    rq.CommentCount,
    ts.TagName,
    ts.QuestionCount,
    uvs.UserId,
    uvs.UpVotes,
    uvs.TotalVotes
FROM 
    RecentQuestions rq
JOIN 
    TagStats ts ON ts.QuestionCount > 10  
JOIN 
    UserVoteStats uvs ON uvs.TotalVotes > 5  
ORDER BY 
    rq.CreationDate DESC
LIMIT 50;
