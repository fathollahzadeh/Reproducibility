
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankViews,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankRecent
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    AND 
        p.Score >= 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostWithBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ARRAY_AGG(DISTINCT b.Name) AS Badges
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ua.DisplayName AS Author,
    ua.PostsCreated,
    ua.UpvotesReceived,
    ua.DownvotesReceived,
    pwb.Badges,
    rp.RankScore,
    rp.RankViews,
    rp.RankRecent
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
LEFT JOIN 
    PostWithBadges pwb ON rp.PostId = pwb.PostId
WHERE 
    rp.RankScore <= 10 OR rp.RankViews <= 10 OR rp.RankRecent <= 10
ORDER BY 
    rp.RankScore, rp.RankViews, rp.RankRecent;
