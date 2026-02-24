
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '<>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.CommentCount,
        ua.UpVotes,
        ua.DownVotes,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        ub.BadgeNames,
        RANK() OVER (ORDER BY ua.UpVotes - ua.DownVotes DESC) AS Rank
    FROM 
        UserActivity ua
    LEFT JOIN 
        UserBadges ub ON ua.UserId = ub.UserId
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.CommentCount,
    ru.UpVotes,
    ru.DownVotes,
    ru.BadgeCount,
    ru.BadgeNames,
    pt.TagName,
    pt.TagCount
FROM 
    RankedUsers ru
CROSS JOIN 
    PopularTags pt
WHERE 
    ru.Rank <= 10  
    AND ru.CommentCount > 5  
ORDER BY 
    (ru.UpVotes - ru.DownVotes) DESC, 
    pt.TagCount DESC;
