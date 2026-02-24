WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Tags AS tag
    LEFT JOIN
        Posts AS p ON p.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY
        tag.TagName
),
UserVotes AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users AS u
    LEFT JOIN 
        Votes AS v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0) AS NetVotes
    FROM 
        Posts AS p
    JOIN
        TagCounts AS ps ON p.Tags IS NOT NULL
    LEFT JOIN
        UserVotes AS vs ON vs.UserId = p.OwnerUserId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND p.ViewCount > 100
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.PostCount,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.NetVotes,
    u.DisplayName AS OwnerName
FROM 
    PostStats AS ps
JOIN 
    Users AS u ON u.Id = ps.OwnerUserId
ORDER BY 
    ps.NetVotes DESC, ps.CreationDate DESC
LIMIT 10;