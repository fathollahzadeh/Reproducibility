
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.UpVotes,
    u.DownVotes,
    u.BadgeCount,
    u.Rank,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedUsers u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    (SELECT DISTINCT unnest(string_to_array(substr(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName FROM Posts p) AS tagNames ON true
LEFT JOIN 
    Tags t ON t.TagName = tagNames.TagName
WHERE 
    u.Rank <= 10
GROUP BY 
    u.UserId, u.DisplayName, u.PostCount, u.QuestionCount, u.AnswerCount, u.UpVotes, u.DownVotes, u.BadgeCount, u.Rank
ORDER BY 
    u.Rank;
