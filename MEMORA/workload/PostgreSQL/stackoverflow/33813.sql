
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostsCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
        LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
    HAVING 
        COUNT(p.Id) > 0
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
ActiveUserPosts AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        COUNT(rp.PostId) AS ActivePostsCount,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.RankScore) AS TotalRank
    FROM 
        UserActivity ua
        JOIN RankedPosts rp ON ua.UserId = rp.OwnerUserId
    GROUP BY 
        ua.UserId, ua.DisplayName
    HAVING 
        COUNT(rp.PostId) > 0
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.QuestionsCount,
    ua.AnswersCount,
    ua.UpVotes,
    ua.DownVotes,
    ap.ActivePostsCount,
    ap.TotalViews,
    ap.TotalRank,
    pt.TagName,
    pt.PostsCount,
    pt.TotalScore
FROM 
    UserActivity ua
    JOIN ActiveUserPosts ap ON ua.UserId = ap.UserId
    LEFT JOIN PopularTags pt ON pt.PostsCount = (
        SELECT MAX(PostsCount)
        FROM PopularTags
    )
WHERE 
    ua.TotalPosts >= 10
ORDER BY 
    ua.UpVotes DESC, ua.TotalPosts DESC;
