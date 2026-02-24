WITH UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        STRING_AGG(DISTINCT tt.TagName, ', ') AS PopularTags,
        COUNT(ph.Id) AS EditCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        TopTags tt ON p.Tags LIKE '%' || tt.TagName || '%'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    upd.UserId,
    upd.DisplayName,
    upd.TotalPosts,
    upd.Questions,
    upd.Answers,
    upd.Wikis,
    upd.LastPostDate,
    ua.PopularTags,
    ua.EditCount
FROM 
    UserPostDetails upd
JOIN 
    UserActivity ua ON upd.UserId = ua.UserId
ORDER BY 
    upd.TotalPosts DESC, upd.LastPostDate DESC;
