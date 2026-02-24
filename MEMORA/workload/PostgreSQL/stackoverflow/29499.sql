
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%') 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        t.TagName
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

RecentComments AS (
    SELECT 
        c.Id AS CommentId,
        c.Text,
        c.CreationDate,
        p.Title AS PostTitle,
        u.DisplayName AS Author
    FROM 
        Comments c
    JOIN 
        Posts p ON c.PostId = p.Id
    JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Score,
    rp.CreationDate,
    rp.Author,
    ts.TagName,
    ts.PostCount,
    ts.AverageScore,
    us.DisplayName AS UserWithMostBadges,
    us.BadgeCount,
    us.QuestionsAsked,
    rc.CommentId,
    rc.Text AS RecentComment,
    rc.CreationDate AS CommentDate,
    rc.Author AS CommentAuthor
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON ts.PostCount > 5 
LEFT JOIN 
    UserStatistics us ON us.BadgeCount = (
        SELECT MAX(BadgeCount) FROM UserStatistics
    )
LEFT JOIN 
    RecentComments rc ON rc.PostTitle = rp.Title
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, rc.CreationDate DESC;
