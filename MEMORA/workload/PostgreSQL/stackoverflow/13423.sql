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
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(upc.PostCount, 0) AS PostCount,
    COALESCE(upc.QuestionCount, 0) AS QuestionCount,
    COALESCE(upc.AnswerCount, 0) AS AnswerCount,
    COALESCE(uvc.VoteCount, 0) AS VoteCount,
    COALESCE(uvc.UpVotes, 0) AS UpVotes,
    COALESCE(uvc.DownVotes, 0) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    UserPostCounts upc ON u.Id = upc.UserId
LEFT JOIN 
    UserVoteCounts uvc ON u.Id = uvc.UserId
ORDER BY 
    u.Reputation DESC
LIMIT 100;