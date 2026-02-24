
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        MAX(b.Date) AS LastAwarded
    FROM 
        Badges b
    WHERE 
        b.Date >= timestamp '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        b.UserId, b.Name
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersProvided
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName,
    pp.CommentCount,
    u.UserId,
    u.DisplayName AS UserDisplayName,
    u.QuestionsAsked,
    u.AnswersProvided,
    COALESCE(rb.BadgeName, 'No Badge') AS RecentBadge,
    rb.LastAwarded
FROM 
    TopPosts pp
JOIN 
    UserPostStats u ON pp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    RecentBadges rb ON u.UserId = rb.UserId
ORDER BY 
    pp.Score DESC, pp.CommentCount DESC;
