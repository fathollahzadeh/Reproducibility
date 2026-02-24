WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
),
EditorHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        p.Title,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
ActiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(CASE WHEN p.OwnerUserId = u.Id THEN 1 END) AS QuestionsAsked,
        COUNT(CASE WHEN c.UserId = u.Id THEN 1 END) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ub.DisplayName AS UserName,
    ub.BadgeCount,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViewCount,
    e.UserDisplayName AS EditorName,
    e.CreationDate AS EditDate,
    e.Comment AS EditComment,
    e.Text AS EditText,
    aus.Reputation AS UserReputation,
    aus.QuestionsAsked,
    aus.CommentsMade
FROM 
    UserBadges ub
JOIN 
    PopularPosts pp ON pp.ViewCount = (SELECT MAX(ViewCount) FROM PopularPosts)
LEFT JOIN 
    EditorHistory e ON pp.PostId = e.PostId
JOIN 
    ActiveUserStats aus ON aus.UserId = ub.UserId
ORDER BY 
    ub.BadgeCount DESC, 
    aus.Reputation DESC;