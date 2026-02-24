
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), UserRanked AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY UpVotes DESC, QuestionCount DESC, AnswerCount DESC) AS ActivityRank
    FROM 
        UserActivity
)
SELECT 
    UserId, 
    DisplayName, 
    QuestionCount, 
    AnswerCount, 
    CommentCount, 
    UpVotes, 
    DownVotes, 
    BadgeCount,
    ActivityRank
FROM 
    UserRanked
WHERE 
    ActivityRank <= 10
ORDER BY 
    ActivityRank;
