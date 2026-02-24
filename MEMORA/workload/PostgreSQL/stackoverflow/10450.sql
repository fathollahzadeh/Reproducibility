WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
VoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    ps.PostId,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.CreationDate,
    ps.PostType,
    ps.OwnerDisplayName,
    vc.UpVoteCount,
    vc.DownVoteCount
FROM 
    UserPostCounts up
JOIN 
    Users u ON up.UserId = u.Id
JOIN 
    PostStats ps ON ps.OwnerDisplayName = u.DisplayName
JOIN 
    VoteCounts vc ON vc.PostId = ps.PostId
ORDER BY 
    up.PostCount DESC, up.QuestionCount DESC, up.AnswerCount DESC;