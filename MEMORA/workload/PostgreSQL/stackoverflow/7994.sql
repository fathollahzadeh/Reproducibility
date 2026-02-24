WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), PostHistoryDetails AS (
    SELECT 
        ph.Id AS HistoryId,
        ph.PostId,
        p.Title AS PostTitle,
        p.Body AS PostBody,
        p.OwnerDisplayName AS Author,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.Id, ph.PostId, p.Title, p.Body, p.OwnerDisplayName
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ub.DisplayName AS UserName,
    ub.BadgeCount,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    pp.AnswerCount AS PopularPostAnswers,
    pp.CommentCount AS PopularPostComments,
    phd.LastEdited,
    ua.PostsCount,
    ua.UpVotes,
    ua.DownVotes
FROM 
    UserBadges ub
JOIN 
    PopularPosts pp ON ub.UserId = pp.PostId
JOIN 
    PostHistoryDetails phd ON pp.PostId = phd.PostId
JOIN 
    UserActivity ua ON ub.UserId = ua.UserId
WHERE 
    pp.PopularityRank <= 10
ORDER BY 
    ub.BadgeCount DESC, pp.ViewCount DESC;