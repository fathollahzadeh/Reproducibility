WITH TagStats AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.ViewCount ELSE 0 END) AS TotalViewCount
    FROM Tags AS tag
    LEFT JOIN Posts AS p ON p.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY tag.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(coalesce(b.Class, 0)) AS TotalBadges,
        AVG(coalesce(r.Reputation, 0)) AS AvgReputation
    FROM Users AS u
    LEFT JOIN Posts AS p ON p.OwnerUserId = u.Id
    LEFT JOIN Badges AS b ON b.UserId = u.Id
    LEFT JOIN Users AS r ON r.Id = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        count(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Posts AS p
    LEFT JOIN Comments AS c ON c.PostId = p.Id
    LEFT JOIN Votes AS v ON v.PostId = p.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.TotalViewCount,
    ur.DisplayName AS TopUser,
    ur.Reputation AS TopUserReputation,
    ur.PostsCreated AS UserPostCount,
    ur.TotalBadges AS UserBadges,
    rpa.PostId,
    rpa.Title,
    rpa.CreationDate,
    rpa.ViewCount AS RecentPostViewCount,
    rpa.CommentCount AS RecentCommentCount,
    rpa.LastVoteDate
FROM TagStats AS ts
JOIN UserReputation AS ur ON ur.Reputation = (SELECT MAX(Reputation) FROM UserReputation)
JOIN RecentPostActivity AS rpa ON rpa.ViewCount = (SELECT MAX(ViewCount) FROM RecentPostActivity)
ORDER BY ts.TotalViewCount DESC, ts.PostCount DESC
LIMIT 10;