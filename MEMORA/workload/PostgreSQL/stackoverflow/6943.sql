
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(b.Class), 0) AS BadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= '2020-01-01'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserRanking AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        CommentCount,
        BadgePoints,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, QuestionCount DESC, AnswerCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    ur.Rank,
    ur.DisplayName,
    ur.Reputation,
    ur.QuestionCount,
    ur.AnswerCount,
    ur.UpVotes,
    ur.DownVotes,
    ur.CommentCount,
    ur.BadgePoints
FROM 
    UserRanking ur
WHERE 
    ur.Rank <= 10
ORDER BY 
    ur.Rank;
