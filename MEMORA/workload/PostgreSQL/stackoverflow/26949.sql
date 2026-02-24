
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        UserName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TagsUsed,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserPostStats
),
BadgesAwarded AS (
    SELECT 
        Bb.UserId, 
        COUNT(Bb.Id) AS BadgeCount
    FROM 
        Badges Bb
    JOIN 
        TopUsers Tu ON Bb.UserId = Tu.UserId
    GROUP BY 
        Bb.UserId
)
SELECT 
    Tu.UserName, 
    Tu.PostCount, 
    Tu.QuestionCount, 
    Tu.AnswerCount, 
    Tu.TotalViews, 
    Tu.TagsUsed,
    COALESCE(Ba.BadgeCount, 0) AS TotalBadges
FROM 
    TopUsers Tu
LEFT JOIN 
    BadgesAwarded Ba ON Tu.UserId = Ba.UserId
WHERE 
    Tu.Rank <= 10
ORDER BY 
    Tu.Rank;
