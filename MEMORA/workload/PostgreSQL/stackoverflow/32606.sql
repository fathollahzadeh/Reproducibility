
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount, u.DisplayName
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS VotesCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserActivityRanked AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostsCount,
        ua.VotesCount,
        ua.TotalBadgeClass,
        RANK() OVER (ORDER BY ua.PostsCount DESC) AS PostRank
    FROM 
        UserActivity ua
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(tags.Tags, '|')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT Id, Tags FROM Posts) AS tags ON p.Id = tags.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        TagName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostsCount,
    ua.VotesCount,
    ua.TotalBadgeClass,
    ht.PostId,
    ht.Title AS HighScoreTitle,
    ht.Score AS HighScore,
    pt.TagName,
    pt.TagCount
FROM 
    UserActivityRanked ua
LEFT JOIN 
    HighScoringPosts ht ON ht.OwnerDisplayName = ua.DisplayName
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT unnest(string_to_array(ht.Title, ' ')))
WHERE 
    ua.PostRank < 11
ORDER BY 
    ua.PostsCount DESC, ht.Score DESC;
