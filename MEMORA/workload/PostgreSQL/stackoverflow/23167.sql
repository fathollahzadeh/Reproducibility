WITH UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUserStats AS (
    SELECT 
        ud.UserId,
        ud.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.ClosedPosts, 0) AS ClosedPosts,
        ROW_NUMBER() OVER (ORDER BY ud.Reputation DESC) AS UserRank
    FROM UserDetails ud
    LEFT JOIN PostStats ps ON ud.UserId = ps.OwnerUserId
    WHERE ud.LastAccessDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.OwnerUserId
),
FinalStats AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.TotalPosts,
        au.QuestionCount,
        au.AnswerCount,
        au.ClosedPosts,
        pd.PostId,
        pd.Title,
        pd.Tags,
        pd.CreationDate,
        pd.ViewCount,
        pd.CommentCount,
        MAX(pd.ViewCount) OVER (PARTITION BY au.UserId) AS MaxViewCount
    FROM ActiveUserStats au
    JOIN PostDetails pd ON au.UserId = pd.OwnerUserId
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.TotalPosts,
    fs.QuestionCount,
    fs.AnswerCount,
    fs.ClosedPosts,
    fs.PostId,
    fs.Title,
    fs.Tags,
    fs.CreationDate,
    fs.ViewCount,
    fs.CommentCount,
    fs.MaxViewCount,
    CASE 
        WHEN fs.ViewCount > 100 THEN 'High Engagement'
        WHEN fs.ViewCount BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM FinalStats fs
WHERE fs.MaxViewCount IS NOT NULL
AND fs.QuestionCount > 0
ORDER BY fs.QuestionCount DESC, fs.TotalPosts DESC;