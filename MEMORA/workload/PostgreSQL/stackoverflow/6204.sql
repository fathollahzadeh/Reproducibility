WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        UpVotes,
        DownVotes,
        TotalViews,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC, TotalViews DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.BadgeCount,
    ru.UpVotes,
    ru.DownVotes,
    ru.TotalViews,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.UserRank
FROM 
    RankedUsers ru
WHERE 
    ru.UserRank <= 10
ORDER BY 
    ru.UserRank, ru.Reputation DESC;