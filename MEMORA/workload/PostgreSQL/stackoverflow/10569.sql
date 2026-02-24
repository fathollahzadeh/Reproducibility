WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Wiki' THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN pt.Name = 'TagWiki' THEN 1 ELSE 0 END) AS TagWikiCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        u.Id, u.DisplayName
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.WikiCount,
    ups.TagWikiCount,
    uvs.VoteCount,
    uvs.UpVotes,
    uvs.DownVotes
FROM 
    UserPostStats ups
LEFT JOIN 
    UserVoteStats uvs ON ups.UserId = uvs.UserId
ORDER BY 
    ups.PostCount DESC, uvs.VoteCount DESC
LIMIT 100;