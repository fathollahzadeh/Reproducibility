WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount, 
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),

ModeratedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        pt.Name AS PostType,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RevisionRank
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    GROUP BY p.Id, p.Title, ph.CreationDate, pt.Name
),

RankedUserActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalViews,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.CommentCount,
        ua.BadgeCount,
        RANK() OVER (ORDER BY ua.PostCount DESC, ua.TotalViews DESC) AS UserRank
    FROM UserActivity ua
)

SELECT 
    rua.UserId,
    rua.DisplayName,
    rua.PostCount,
    rua.TotalViews,
    rua.QuestionCount,
    rua.AnswerCount,
    rua.CommentCount,
    rua.BadgeCount,
    mp.Title AS LatestModerationTitle,
    mp.PostId AS ModeratedPostId,
    mp.PostType,
    mp.VoteCount AS TotalUpvotes,
    mp.CreationDate AS LastModerationDate
FROM RankedUserActivity rua
LEFT JOIN ModeratedPosts mp ON rua.UserId = mp.PostId
WHERE rua.BadgeCount > 0
  AND (rua.CommentCount > 5 OR rua.TotalViews > 1000)
ORDER BY rua.UserRank, mp.VoteCount DESC NULLS LAST;