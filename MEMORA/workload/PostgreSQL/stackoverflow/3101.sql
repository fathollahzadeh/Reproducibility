WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
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
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        CommentCount,
        BadgeCount,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY UpVotes DESC) AS UpVoteRank
    FROM 
        UserActivity
)
SELECT 
    ru.DisplayName,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.UpVotes,
    ru.DownVotes,
    ru.CommentCount,
    ru.BadgeCount,
    ru.TotalViews
FROM 
    RankedUsers ru
WHERE 
    ru.ViewRank <= 10
    OR (ru.UpVoteRank <= 5 AND ru.BadgeCount > 3)
ORDER BY 
    ru.TotalViews DESC, ru.UpVotes DESC;
